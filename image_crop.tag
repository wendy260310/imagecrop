<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bw" uri="/tags" %>
<%@ tag pageEncoding="UTF-8" %>
<%@ attribute name="doAfterPopUpClose" required="false" %>
<%@ attribute name="doAfterFinishCropImg" required="true" %>
<%@ attribute name="ratioOptions" required="true" type="java.util.Map" %>
<%@ attribute name="imageInfoHolder" required="false" fragment="true" %>
<%@ attribute name="imageInfoInput" required="false" fragment="true" %>
<%@ attribute name="fillInfoHolderWhenSave" required="false" %>
<%@ attribute name="clearImageInfoInput" required="false" %>
<%@ attribute name="imageRatioChangedCallBack" required="false" %>
<%@ attribute name="checkInputCallBack" required="false" %>
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
            overflow: auto;
        }

        #bw-upload-img-pop-up canvas {
            margin: 20px 0px 20px 20px;
            border: 1px dotted;
            background-color: grey;
        }

        #bw-edit-img-option {
            display: inline-block;
            margin-top: 20px;
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

        #bw-cropped-img-container ul::after {
            display: block;
            content: '';
            clear: both;
        }

        #bw-cropped-img-container li {
            width: 150px;
            position: relative;
            float: left;
            padding-right: 10px;
        }

        .remove-cropped-img {
            position: absolute;
            top: -5px;
            right: 10px;
            font-size: 20px;
        }

        .remove-cropped-img:hover {
            cursor: pointer;
            background-color: #468847;
        }

        .bw-upload-img-high-light {
            background-color: #468847;
        }

        .m-w-100 {
            max-width: 100px;
        }

        .not-display {
            display: none;
        }

        .p-d-10 {
            padding: 10px;
            max-width: 150px;
        }

        .img-selected {
            border: solid 2px #4bb1cf;
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
            window.bwShowUploadPopUp = function (doBeforeShowUploadPopUp, index) {

                if (typeof doBeforeShowUploadPopUp === 'function')
                    doBeforeShowUploadPopUp();

                $('#bw-upload-img-overlay').css('visibility', 'visible');
                window.imgCrop.resetCanvas().setCanvasWidthAndHeight(window.imgRatioOptions[$('select', '#bw-edit-img-option').val()].x, window.imgRatioOptions[$('select', '#bw-edit-img-option').val()].y)
                        .setShowImgInfoCallBack(function (width, height) {
                            $($('#bw-edit-img-option').find('.control-group').get(1)).find('label').get(1).innerHTML = width + "*" + height;
                        }, function (scale) {
                            $('#scale-range').find('input').val(scale);
                            $('#scale-range').find('label').eq(1).text($('#scale-range').find('input').val());

                        }, function (width, height, ratio) {
                            $('#ratio-info').find('input').get(0).value = width;
                            $('#ratio-info').find('input').get(1).value = height;
                            $('#ratio-info').find('label').get(1).innerText = ratio;
                        });
                $('ul', '#bw-cropped-img-container').empty();
                $('#bw-ori-img-container').empty();
                $('#compress-check-box').prop('checked', true);
                if (index !== undefined) {
                    $('#bw-cropped-img-container').data('edit-item-index', index);
                } else {
                    $('#bw-cropped-img-container').removeData("edit-item-index");

                    <c:if test="${not empty imageRatioChangedCallBack}">
                    if (typeof ${imageRatioChangedCallBack} === 'function') {
                        ${imageRatioChangedCallBack}($('#img-style-select').val());
                    }
                    </c:if>
                }
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
                    imgCrop.resetCanvas();
                    $("#use-ori-img").prop('disabled', true).prop('checked', false).trigger('change');
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
            window.imgRatioOptions = {
                <c:forEach items="${ratioOptions}" var="keySet" varStatus="outloop">
                "${keySet.key.toString()}": {
                    <c:forEach items="${keySet.value}" var="option" varStatus="loop">
                    "${option.key}":${option.value}
                    ${loop.last?"":","}
                    </c:forEach>
                }${outloop.last?"":","}
                </c:forEach>
            }
        }
        if (typeof imgCrop === "undefined") {
            window.imgCrop = (function () {
                var scale;//缩放比例
                var ratio;//截图长宽比
                var moving;//用户是否在移动图片
                var listenToMouseMove;
                var imgLoaded;//是否已经加载图片.图片在没有加载的情况下,canvas是不会响应mouse event.
                var offsetX, offsetY;//图片相对于canvas的偏移,因为有可能有多次移动,需要记录下上一次移动到哪儿了
                var mouseDownPosX, mouseDownPosY;
                var canvasWidth, canvasHeight;
                var fileReader;//用来读取图片
                var img;//读取到这个地方

                var _imgOriInfoCallBack, _imgScaleCallback, _imgRatioCallBack;

                var canvas, ctx;

                function _readImgIntoCanvas(file) {
                    _resetParam();
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
                        if (imgLoaded && moving && listenToMouseMove) {

                            var x = offsetX + event.pageX - mouseDownPosX;
                            var y = offsetY + event.pageY - mouseDownPosY;
                            _drawImg(x, y);

                        }
                    }).mouseup(function (event) {
                        moving = false;

                        offsetX = offsetX + event.pageX - mouseDownPosX;
                        offsetY = offsetY + event.pageY - mouseDownPosY;

                    }).mousedown(function (event) {
                        mouseDownPosX = event.pageX;
                        mouseDownPosY = event.pageY;
                        moving = true;
                    }).mouseout(function (event) {
                        if (imgLoaded && moving && listenToMouseMove) {

                            moving = false;
                            var x = offsetX + event.pageX - mouseDownPosX;
                            var y = offsetY + event.pageY - mouseDownPosY;
                            _drawImg(x, y);
                            offsetX = offsetX + event.pageX - mouseDownPosX;
                            offsetY = offsetY + event.pageY - mouseDownPosY;

                        }
                    });

                    $('#scale-range').off('change').on('change', 'input', (event)=> {
                        $(event.currentTarget).next().val(event.currentTarget.value);
                        scale = event.currentTarget.value;
                        $(event.currentTarget).next().text(scale);
                        _resetParam();
                        if (imgLoaded) {
                            _drawImg(0, 0);
                        }
                    });

                    $('#ratio-info').off('change').on('change', 'input', (event)=> {
                        let $controls = $(event.currentTarget).closest('.controls');
                        let width = parseInt($controls.find('input').eq(0).val());
                        let height = parseInt($controls.find('input').eq(1).val());
                        _setCanvasWidthAndHeight(width, height);
                    });

                    $('#use-ori-img').on('change', (event)=> {
                        if ($(event.currentTarget).prop('checked')) {
                            _resetParam();
                            let $selectImg = $('#bw-ori-img-container').find('.img-selected');
                            $('#scale-range').find('input').eq(0).val(1);
                            canvasWidth = $selectImg.data('width');
                            canvasHeight = $selectImg.data('height');
                            scale = 1;
                            _showImgInfo();
                            //disable other selection
                            $('#ratio-info').find('input').prop('disabled', true);
                            $('#scale-range').find('input').prop('disabled', true);
                            $("#img-style-select").prop('disabled', true);
                            $('#compress-check-box').prop('disabled', true);
                            //disable mouse event
                            listenToMouseMove = false;
                        } else {
                            //enable other selection
                            $('#ratio-info').find('input').prop('disabled', false);
                            $('#scale-range').find('input').prop('disabled', false);
                            $("#img-style-select").prop('disabled', false);
                            $('#compress-check-box').prop('disabled', false);

                            listenToMouseMove = true;

                            $('#img-style-select').click();
                        }
                    });


                    $('#bw-ori-img-container').off('click').on('click', 'span', (event)=> {
                        if (!$(event.currentTarget).find('img').hasClass('img-selected')) {
                            $(event.delegateTarget).find('img').removeClass('img-selected');
                            $(event.currentTarget).find('img').addClass('img-selected');
                            <c:if test="${not empty clearImageInfoInput}">
                            if (typeof ${clearImageInfoInput} === 'function')
                                ${clearImageInfoInput}()
                            </c:if>
                            _readImgIntoCanvas($('#img-input').get(0).files[$(event.currentTarget).index()]);
                            //主要是保证一次处理的宽高比相同
                            $('#ratio-info').find('input').eq(0).trigger('change');
                        }
                    });

                }

                function _showImgInfo() {
                    if (_imgOriInfoCallBack !== undefined)
                        _imgOriInfoCallBack(img.width, img.height);
                    if (_imgScaleCallback !== undefined)
                        _imgScaleCallback(scale);
                    if (_imgRatioCallBack !== undefined)
                        _imgRatioCallBack(canvasWidth, canvasHeight, ratio);
                }

                function _resetParam() {
                    offsetX = 0;
                    offsetY = 0;
                    moving = false;
                    listenToMouseMove = true;


                    mouseDownPosX = 0;
                    mouseDownPosY = 0;

                    //clear canvas
                    ctx.clearRect(0, 0, canvas.width, canvas.height);
                }

                function _setCanvasWidthAndHeight(width, height) {
                    _resetParam();
                    canvasWidth = width;
                    canvasHeight = height;
                    ratio = new Number(canvasWidth / canvasHeight).toFixed(5);
                    if (imgLoaded) {
                        _computeScale();
                        _showImgInfo();
                        _drawImg(0, 0);
                    }
                }

                function _computeScale() {
                    //图片的比较宽
                    if (img.width * canvasHeight > img.height * canvasWidth) {
                        canvasWidth = img.width > canvasWidth ? canvasWidth : img.width;
                        canvasHeight = img.width > canvasWidth ? canvasHeight : Math.floor(canvasWidth * img.height / img.width);
                        scale = new Number(canvasWidth / img.width).toFixed(5);
                    } else {
                        canvasHeight = img.height > canvasHeight ? canvasHeight : img.height;
                        canvasWidth = img.height > canvasHeight ? canvasWidth : Math.floor(canvasHeight * img.width / img.height);
                        scale = new Number(canvasHeight / img.height).toFixed(5);
                    }
                }

                function _getCanvasBytes(compress) {
                    if (imgLoaded) {

                        return compress ? canvas.toDataURL("image/webp", 0.2) : canvas.toDataURL("image/webp");
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
                        _setCanvasWidthAndHeight(width, height);
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
                    getCroppedImg: function (compress) {
                        return _getCanvasBytes(compress);
                    }
                }
            })();
        }

        if (typeof bwImageRatioChanged !== 'function') {
            window.bwImageRatioChanged = function (item) {
                window.imgCrop.setCanvasWidthAndHeight(window.imgRatioOptions[$(item).val()].x, window.imgRatioOptions[$(item).val()].y);
                <c:if test="${not empty imageRatioChangedCallBack}">
                if (typeof ${imageRatioChangedCallBack} === 'function') {
                    ${imageRatioChangedCallBack}(item.value);
                }
                </c:if>
            }
        }
        if (typeof bwUploadImgClicked !== 'function') {
            window.bwUploadImgClicked = function (item) {
                if (item.files.length == 0)
                    return;
                $('#bw-ori-img-container').empty();

                var files = item.files;
                for (let i = 0; i < files.length; ++i) {
                    let imgDom = $('#bw-ori-img-wrapper').find('span').clone();
                    $('#bw-ori-img-container').append(imgDom);
                }
                //注意 onload 是异步的,所以加载的次序可能和files里面原来的顺序不一样
                for (let i = 0; i < files.length; ++i) {
                    let reader = new FileReader();
                    reader.onload = function (e) {
                        let t = new Image;
                        t.onload = function () {
                            $('#bw-ori-img-container').find('img').eq(i).attr('src', t.src).data({
                                'srcByte': e.target.result,
                                'offset': files[i].type.length + 13,
                                'width': this.width,
                                'height': this.height
                            });
                        }
                        t.src = e.target.result;
                    };
                    reader.readAsDataURL(files[i]);
                }
                $('#bw-ori-img-container').find('img').eq(0).addClass('img-selected');
                $(item).data('selected-image-index', 0)
                $('#use-ori-img').prop('disabled', false);

                window.imgCrop.readImg(item.files[0]);
            }
        }

        if (typeof bwSaveCropImg !== 'function') {

            window.bwSaveCropImg = function () {
                var data, offset;
                if ($('#use-ori-img').prop('checked')) {
                    let $selectedImg = $('#bw-ori-img-container').find('.img-selected');
                    data = $selectedImg.data('srcByte');
                    offset = $selectedImg.data('offset');
                } else {
                    data = window.imgCrop.getCroppedImg($('#compress-check-box').prop('checked'));
                    offset = 23;
                }
                if (data == undefined) {
                    alert("没有图片");
                    return;
                }
                var dom = $('li', '#bw-crop-img-wrapper').clone();
                $(dom).find('img')[0].src = data;
                $(dom).find('img')[0].dataset.srcByte = data;
                $(dom).find('img')[0].dataset.offset = offset;
                dom.find('.img-ratio-info').eq(0).find('span').eq(0).text($('#ratio-info').find('input').eq(0).val()).end().eq(1).text($('#ratio-info').find('input').eq(1).val());


                $('ul', '#bw-cropped-img-container').append(dom);

                <c:if test="${not empty fillInfoHolderWhenSave}">
                if (typeof ${fillInfoHolderWhenSave} !== "function") {
                    alert("fillInfoHolderWhenSave is not a function");
                    return;
                } else {
                    ${fillInfoHolderWhenSave}(dom);
                }
                </c:if>
                var currentImageIndex = $('#img-input').data('selected-image-index');
                if (currentImageIndex < $('#img-input').get(0).files.length - 1) {
                    <c:if test="${not empty clearImageInfoInput}">
                    if (typeof ${clearImageInfoInput} === 'function')
                        ${clearImageInfoInput}()
                    </c:if>
                    window.imgCrop.readImg($('#img-input').get(0).files[currentImageIndex + 1]);
                    $('#img-input').data('selected-image-index', currentImageIndex + 1);
                    $('#ratio-info').find('input').eq(0).trigger('change');
                    $('#bw-ori-img-container').find('img').removeClass('img-selected').eq(currentImageIndex + 1).addClass('img-selected');
                }
            };
        }

        if (typeof bwFinishCropImg !== 'function') {

            window.bwFinishCropImg = function (finishCropCallBack) {
                if (typeof finishCropCallBack !== 'function') {
                    alert("finish crop call back is undefined !")
                    return;
                }
                var croppedArray = $('img', '#bw-cropped-img-container').map(function () {
                    return this.dataset.srcByte;
                }).get();
                $('#bw-cropped-img-container').data({
                    'width': parseInt($('#ratio-info').find('input').eq(0).val()),
                    'height': parseInt($('#ratio-info').find('input').eq(1).val())
                });
                <c:if test="${ not empty checkInputCallBack}">
                if (typeof ${checkInputCallBack} === 'function') {
                    if (!${checkInputCallBack}($('#bw-cropped-img-container'))) {
                        return;
                    }
                }
                </c:if>
                finishCropCallBack(croppedArray, $('#bw-cropped-img-container'));

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
            <div style="display: inline-block">
                <canvas>
                </canvas>
                <h4>原图:</h4>
                <div id="bw-ori-img-container">

                </div>
                <h4>裁剪结果:</h4>
                <div id="bw-cropped-img-container">
                    <ul class="ul-sortable"></ul>
                </div>
            </div>
            <div id="bw-edit-img-option">
                <div class="form-horizontal">
                    <bw:controlgrouptemplate label="样式">
                        <select id="img-style-select" onclick="bwImageRatioChanged(this)">
                            <c:forEach items="${ratioOptions}" var="keySet">
                                <option value="${keySet.key.toString()}">${keySet.key.toString()}</option>
                            </c:forEach>
                        </select>
                    </bw:controlgrouptemplate>
                    <bw:controlgrouptemplate label="原始图片信息">
                        <label style="margin-top: 5px"></label>
                    </bw:controlgrouptemplate>
                    <bw:controlgrouptemplate label="是否压缩">
                        <input type="checkbox" checked="checked" id="compress-check-box">
                    </bw:controlgrouptemplate>

                    <bw:controlgrouptemplate label="是否使用原图">
                        <input type="checkbox" id="use-ori-img" disabled="disabled">
                    </bw:controlgrouptemplate>
                    <bw:controlgrouptemplate label="图片缩放比例" id="scale-range">
                        <input type="range" min="0" max="1" step="0.05">
                        <label></label>
                    </bw:controlgrouptemplate>
                    <bw:controlgrouptemplate label="自定义截取宽高" id="ratio-info">
                        <input type="text" placeholder="宽" class="m-w-100">
                        <input type="text" placeholder="高" class="m-w-100">
                        <label class="m-w-100"></label>
                    </bw:controlgrouptemplate>
                    <bw:controlgrouptemplate label="上传图片">
                        <input type="file" onchange="bwUploadImgClicked(this)" id="img-input" multiple="multiple">
                    </bw:controlgrouptemplate>
                    <c:if test="${not empty imageInfoInput}">
                        <jsp:invoke fragment="imageInfoInput"/>
                    </c:if>
                    <bw:controlgrouptemplate>
                        <a class="btn btn-primary" onclick="bwCloseUploadPopUp(${doAfterPopUpClose})">取消</a>
                        <a class="btn btn-primary" onclick="bwSaveCropImg()">保存</a>
                        <a class="btn btn-primary" onclick="bwFinishCropImg(${doAfterFinishCropImg})">完成</a>
                    </bw:controlgrouptemplate>
                </div>
            </div>

        </div>
        <div id="bw-ori-img-wrapper" class="not-display">
            <span>
                <img src="" class="p-d-10">
            </span>
        </div>
        <div id="bw-crop-img-wrapper" class="not-display">
            <li>
                <img src="" data-src-byte="" data-offset="">
                <a onclick="bwRemoveSavedCropImg(this)" class="remove-cropped-img">&times;</a>
                <div class="img-ratio-info">
                    <span></span>
                    <span></span>
                </div>
                <c:if test="${not empty imageInfoHolder}">
                    <jsp:invoke fragment="imageInfoHolder"/>
                </c:if>
            </li>
        </div>
    </div>
</c:if>
