<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ tag pageEncoding="UTF-8" %>
<%@ attribute name="doAfterPopUpClose" required="false" %>
<%@ attribute name="doAfterFinishCropImg" required="true" %>
<%@ attribute name="ratioOptions" required="true" type="java.util.List" %>
<%@ attribute name="ratioNames" required="true" type="java.util.List" %>
<%-- import only once --%>
<c:if test="${ empty bwImgCropTemplateImported }">
    <c:set var="bwImgCropTemplateImported" value="1" scope="request"></c:set>
    <style type="text/css">
        #bw-upload-img-overlay {
            transition: opacity 500ms ease-in-out;
            position: fixed;
            top: 0;
            bottom: 0;
            left: 0;
            right: 0;
            background-color: grey;
            visibility: hidden;
            z-index: 999;
        }

        #bw-upload-img-pop-up {
            position: relative;
            height: 90%;
            width: 90%;
            margin: 50px 50px 50px 50px;
            background: #fff;
            border-radius: 5px;
        }

        #bw-upload-img-pop-up canvas {
            margin: 20px 0px 20px 20px;
            border: 1px dotted;
            background-color: grey;
        }

        #bw-edit-img-option {
            display: inline-block;
            top: 20px;
            position: absolute;
        }

        #bw-upload-img-pop-up > a {
            position: absolute;
            top: 20px;
            right: 30px;
            color: #333;
            font-size: 40px;
            text-decoration: double;
            cursor: pointer;
        }

        #bw-upload-img-pop-up > a:hover {
            color: #06D85F;
        }

        #bw-cropped-img-container ul {
            list-style: none;
        }

        #bw-cropped-img-container li {
            width: 150px;
            position: relative;
            float: left;
            padding-right: 10px;
        }

        #bw-cropped-img-container li a {
            position: absolute;
            top: -5px;
            right: 10px;
            font-size: 20px;
        }

        #bw-cropped-img-container li a:hover {
            cursor: pointer;
            background-color: #468847;
        }

        .bw-upload-img-high-light {
            background-color: #468847;
        }

        #bw-cropped-img-container li img {
            width: 100%;
        }

    </style>
    <script>
        if (typeof window.jQuery === "undefined")
            alert("image_crop 这个tag依赖jQuery,请确认在引入该tag之前已经引入了jQuery");

        if (typeof jQuery.ui === "undefined")
            alert("image_crop  这个tag依赖 jQuery ui,请确保已经引入了jQuery.ui")

        $(function () {
            $('ul', '#bw-cropped-img-container').sortable(
                    {
                        placeholder: 'bw-upload-img-high-light',
                        opacity: 0.6,
                        tolerance: 'pointer',
                        forcePlaceholderSize: true
                    }
            );
            window.imgCrop.init();
        });

        if (typeof bwShowUploadPopUp !== 'function') {
            window.bwShowUploadPopUp = function (doBeforeShowUploadPopUp) {

                if (typeof doBeforeShowUploadPopUp === 'function')
                    doBeforeShowUploadPopUp();
                $('#bw-upload-img-overlay').css('visibility', 'visible');
                window.imgCrop.resetCanvas().setCanvasWidthAndHeight(window.imgRatioOptions[parseInt($('select', '#bw-edit-img-option').val())].x, window.imgRatioOptions[parseInt($('select', '#bw-edit-img-option').val())].y)
                        .setShowImgInfoCallBack(function (width, height) {
                            $($('#bw-edit-img-option').find('.control-group').get(1)).find('label').get(1).innerHTML = width + "*" + height;
                        }, function (scale) {
                            $($('#bw-edit-img-option').find('.control-group').get(2)).find('input').val(scale);
                        }, function (ratio) {
                            $($('#bw-edit-img-option').find('.control-group').get(3)).find('input').val(ratio);
                        });
                $('ul', '#bw-cropped-img-container').empty();
            }
        }

        if (typeof bwCloseUploadPopUp !== "function") {
            window.bwCloseUploadPopUp = function (doAfterClosePupUpCallBack) {

                if ($('#bw-upload-img-overlay').is(':visible')) {
                    $('#bw-upload-img-overlay').css('visibility', 'hidden');
                    //reset option
                    $($('#bw-edit-img-option').find('.control-group').get(1)).find('label').get(1).innerHTML = '';
                    $($('#bw-edit-img-option').find('.control-group').get(2)).find('input').val("");
                    $($('#bw-edit-img-option').find('.control-group').get(3)).find('input').val("");
                    //empty input file
                    $('#bw-edit-img-option').find('input:file').val("");
                    //empty crop list
                    $('ul', '#bw-cropped-img-container').empty();
                    //用户在关闭了pop up之后可能会显示别的东西
                    if (typeof  doAfterClosePupUpCallBack === 'function')
                        doAfterClosePupUpCallBack();
                }
            }
        }
        if (typeof imgRatioOptions === "undefined") {
            window.imgRatioOptions = [
                <c:forEach items="${ratioOptions}" var="option" varStatus="loop">
                {x:${option.x}, y:${option.y}}${loop.last?"":","}
                </c:forEach>
            ]
        }
        if (typeof imgCrop === "undefined") {
            window.imgCrop = (function () {
                var scale;//缩放比例
                var ratio;//截图长宽比
                var moving;//用户是否在移动图片
                var imgLoaded;//是否已经加载图片.图片在没有加载的情况下,canvas是不会响应mouse event.
                var offsetX, offsetY;//图片相对于canvas的偏移,因为有可能有多次移动,需要记录下上一次移动到哪儿了
                var widthFirst;//计算ratio的时候是不是以width为参考,如果以width为参考,左右移动图片将会失败
                var mouseDownPosX, mouseDownPosY;
                var canvasWidth, canvasHeight;
                var fileReader;//用来读取图片
                var img;//读取到这个地方

                var _imgOriInfoCallBack, _imgScaleCallback, _imgRatioCallBack;

                var canvas, ctx;

                function _readImgIntoCanvas(file) {
                    fileReader.onload = function (event) {
                        img.src = event.target.result;
                        img.onload = function () {
                            _resetParam();
                            _computeScale();
                            _showImgInfo();
                            _drawImg(0, 0);
                            imgLoaded = true;
                        }
                    }
                    fileReader.readAsDataURL(file);
                }

                function _drawImg(x, y) {
                    //如果img.height*ratio>img.width说明按照现在的宽高比计算高度太大了,高会被截取一部分

                    canvas.width = canvasWidth;
                    canvas.height = canvasHeight;
                    //注意参数x,y表示的是图片(0,0)在canvas的坐标
                    ctx.drawImage(img, x, y, img.width * scale, img.height * scale);
                }

                function _bindAction() {
                    $(canvas).mousemove(function (event) {
                        if (imgLoaded && moving) {

                            var x = widthFirst ? 0 : (offsetX + event.pageX - mouseDownPosX);
                            var y = widthFirst ? (offsetY + event.pageY - mouseDownPosY) : 0;
                            _drawImg(x, y);

                        }
                    }).mouseup(function (event) {
                        moving = false;
                        //如果当前显示以width为准,X方向是没有偏移的
                        offsetX = widthFirst ? 0 : (offsetX + event.pageX - mouseDownPosX);
                        offsetY = widthFirst ? (offsetY + event.pageY - mouseDownPosY) : 0;

                    }).mousedown(function (event) {
                        mouseDownPosX = event.pageX;
                        mouseDownPosY = event.pageY;
                        moving = true;
                    }).mouseout(function (event) {
                        if (imgLoaded && moving) {

                            moving = false;
                            var x = widthFirst ? 0 : (offsetX + event.pageX - mouseDownPosX);
                            var y = widthFirst ? (offsetY + event.pageY - mouseDownPosY) : 0;
                            _drawImg(x, y);
                            offsetX = widthFirst ? 0 : (offsetX + event.pageX - mouseDownPosX);
                            offsetY = widthFirst ? (offsetY + event.pageY - mouseDownPosY) : 0;

                        }
                    });
                }

                function _showImgInfo() {
                    if (_imgOriInfoCallBack !== undefined)
                        _imgOriInfoCallBack(img.width, img.height);
                    if (_imgScaleCallback !== undefined)
                        _imgScaleCallback(scale);
                    if (_imgRatioCallBack !== undefined)
                        _imgRatioCallBack(ratio);
                }

                function _resetParam() {
                    offsetX = 0;
                    offsetY = 0;
                    moving = false;


                    mouseDownPosX = 0;
                    mouseDownPosY = 0;

                    widthFirst = false;
                    //clear canvas
                    ctx.clearRect(0, 0, canvas.width, canvas.height);
                }

                function _computeScale() {
                    //说明高需要截取一部分
                    if (img.height * ratio > img.width) {
                        //这里说明 canvasWidth不会大于img.width,也就是说不会出现放大图片的情况
                        canvasWidth = (img.width < canvasWidth) ? img.width : canvasWidth;
                        canvasHeight = Math.floor(canvasWidth / ratio);
                        scale = new Number(canvasWidth / img.width).toFixed(5)
                        widthFirst = true;
                    }
                    else {
                        canvasHeight = (img.height < canvasHeight) ? img.height : canvasHeight;
                        canvasWidth = Math.floor(canvasHeight * ratio);
                        scale = new Number(canvasHeight / img.height).toFixed(5)
                        widthFirst = false;
                    }
                }

                function _getCanvasBytes() {
                    if (imgLoaded) {
                        return canvas.toDataURL();
                    }
                    return undefined;
                }


                return {
                    init: function () {
                        canvas = $('canvas', '#bw-upload-img-pop-up').get(0);
                        ctx = canvas.getContext('2d');
                        img = new Image();
                        fileReader = new FileReader();
                        imgLoaded = false;
                        _resetParam();
                        _bindAction();
                        return this;
                    },
                    readImg: function (file) {
                        _readImgIntoCanvas(file);
                        return this;
                    },
                    setCanvasWidthAndHeight: function (width, height) {
                        _resetParam();
                        canvasWidth = width;
                        canvasHeight = height;
                        ratio = new Number(canvasWidth / canvasHeight).toFixed(5);
                        if (imgLoaded) {
                            _computeScale();
                            _showImgInfo();
                            _drawImg(0, 0);
                        }
                        return this;
                    },
                    setShowImgInfoCallBack: function (imgOriInfoCallBack, imgScaleCallback, imgRatioCallBack) {
                        _imgOriInfoCallBack = imgOriInfoCallBack;
                        _imgScaleCallback = imgScaleCallback;
                        _imgRatioCallBack = imgRatioCallBack;
                        return this;
                    },
                    resetCanvas: function () {
                        imgLoaded = false;
                        _resetParam();
                        return this;
                    },
                    getCroppedImg: function () {
                        return _getCanvasBytes();
                    }
                }
            })();
        }

        if (typeof bwImageRatioChanged !== 'function') {
            window.bwImageRatioChanged = function (item) {
                window.imgCrop.setCanvasWidthAndHeight(window.imgRatioOptions[parseInt($(item).val())].x, window.imgRatioOptions[parseInt($(item).val())].y);
            }
        }
        if (typeof bwUploadImgClicked !== 'function') {
            window.bwUploadImgClicked = function (item) {
                window.imgCrop.readImg(item.files[0]);
            }
        }

        if (typeof bwSaveCropImg !== 'function') {

            window.bwSaveCropImg = function () {
                var data = window.imgCrop.getCroppedImg();
                if (data == undefined) {
                    alert("没有图片");
                    return;
                }
                var dom = $('li', '#bw-crop-img-wrapper').clone();
                $(dom).find('img')[0].src = data;
                $(dom).find('img')[0].dataset.srcByte = data;
                $('ul', '#bw-cropped-img-container').append(dom);
            };
        }

        if (typeof bwFinishCropImg !== 'function') {

            window.bwFinishCropImg = function (finishCropCallBack) {

                if (typeof finishCropCallBack === 'undefined') {
                    alert("finish crop call back is undefined !")
                    return;
                }
                var croppedArray = $('img', '#bw-cropped-img-container').map(function () {
                    return this.dataset.srcByte;
                }).get();
                finishCropCallBack(croppedArray);

                window.bwCloseUploadPopUp(${doAfterPopUpClose});
            };
        }

        if (typeof bwRemoveSavedCropImg !== 'function') {
            window.bwRemoveSavedCropImg = function (item) {
                var forSure = confirm('确认要删除吗?')
                if (forSure) {
                    $(item).closest('li').remove();
                }
            }
        }
    </script>
    <div id="bw-upload-img-overlay">
        <div id="bw-upload-img-pop-up" data-upload="">
            <a onclick="bwCloseUploadPopUp(${doAfterPopUpClose})">&times;</a>
            <canvas>
            </canvas>
            <div id="bw-edit-img-option">
                <div class="form-horizontal">
                    <div class="control-group">
                        <label class="control-label">样式:</label>

                        <div class="controls">
                            <select id="img-style-select" onchange="bwImageRatioChanged(this)">
                                <c:forEach items="${ratioNames}" varStatus="i" var="name">
                                    <option value="${i.index}">${name}</option>
                                </c:forEach>
                            </select>
                        </div>
                    </div>
                    <div class="control-group">
                        <label class="control-label">原始图片信息:</label>

                        <div class="controls">
                            <label style="margin-top: 5px"></label>
                        </div>
                    </div>
                    <div class="control-group">
                        <label class="control-label">图片缩放比例:</label>

                        <div class="controls">
                            <input type="text" placeholder="图片缩放比例">
                        </div>
                    </div>
                    <div class="control-group">
                        <label class="control-label">图片截取比例:</label>

                        <div class="controls">
                            <input type="text" placeholder="图片截取比例">
                        </div>
                    </div>
                    <div class="control-group">
                        <label class="control-label">上传图片:</label>

                        <div class="controls">
                            <input type="file" onchange="bwUploadImgClicked(this)">
                        </div>
                    </div>
                    <div class="control-group">
                        <div class="controls">
                            <a class="btn btn-primary" onclick="bwCloseUploadPopUp(${doAfterPopUpClose})">取消</a>
                            <a class="btn btn-primary" onclick="bwSaveCropImg()">保存</a>
                            <a class="btn btn-primary" onclick="bwFinishCropImg(${doAfterFinishCropImg})">完成</a>
                        </div>
                    </div>
                </div>
            </div>
            <div id="bw-cropped-img-container">
                <ul class="ul-sortable"></ul>
            </div>
        </div>
        <div id="bw-crop-img-wrapper" style="display: none">
            <li>
                <img src="" data-src-byte="">
                <a onclick="bwRemoveSavedCropImg(this)">&times;</a>
            </li>
        </div>
    </div>
</c:if>
