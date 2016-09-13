/**
 * Created by mi on 9/12/16.
 */
var cropModule = (function () {
    //img reader
    var reader = new FileReader();
    //img
    var img = new Image();
    var canvas, ctx;
    //scale
    var scale = 1.0;
    var maxScale;
    //init aspectRatio
    var aspectRatio = 2.0;

    var canvasWidth, canvasHeight;

    var inputDom;

    function init() {
        appendDom();
        canvas = $('#crop-canvas')[0];
        ctx = canvas.getContext("2d");
        bindActon();
    }

    function appendDom() {
        var cropPopUpCss = "<style type='text/css'>" +
            ".not-display{ display:none;} " +
            "#crop-pop-up{ position: absolute;top: 10%;left: 15%;width: 70% ;height: 70%;z - index:10;border: solid 2px;background: white;}" +
            ".on-blur {background-color:gray}" +
            "#canvas-container {  float : left; margin : 10% ; height: 60% ; width: 60%; border: solid 1px ; position : absolute ; }" +
            "#cut-frame,#crop-canvas {width: 100%;height: 100%; position : absolute; top :0 ; left:0 }" +
            "#crop-canvas { z-index : 100 ; background : grey}" +
            "#crop-options {  float:right; margin-right: 25px; margin-top: 25px }" +
            ".close-pop-up {float:right;margin-top:-10px;margin-right:-10px;cursor:pointer;color:#fff;border: 1px solid #AEAEAE;border-radius: 30px;background: #605F61;font-size: 31px;font-weight: bold;display: inline-block;line-height: 0px;padding: 11px 3px; } " +
            ".close-pop-up:before{ content : '×' }" +
            ".c-b { clear : both}" +
            "</style>";

        var cropPopUpTemplate = "<div class='not-display' id='crop-pop-up'>" +
            "<div><a class='close-pop-up'></a><div class='c-b'></div></div>" +
            "<div id='canvas-container'>" +
            "<canvas id='crop-canvas'></canvas>" +
            "<div id='cut-frame'></div>" +
            "</div>" +
            "<div id='crop-options'>" +
            "<div id='ori-width'></div>" +
            "<div id='ori-height'></div>" +
            "<hr>" +
            "<div id='scale-ratio'>缩放比例:1.0</div>" +
            "<hr>" +
            "<input type='button' value='保存' id='crop-save'><input type='button' value='重置' style='margin-left: 10px' id='crop-reset'>" +
            "</div>" +
            "</div>"

        var cssDom = $.parseHTML(cropPopUpCss);
        var templateDom = $.parseHTML(cropPopUpTemplate);
        //append css
        $('head').append(cssDom);
        //append template
        $('body').append(templateDom);
    }

    function reset() {
        scale = maxScale;
        drawImg();
    }

    function scrollActionHandler(event) {
        var oriEvent = event;
        if (event.originalEvent) {
            oriEvent = event.originalEvent;
        }
        if (oriEvent.deltaY > 0) {
            scale += 0.1;
            if (scale > maxScale)
                scale = maxScale;
        } else {
            scale -= 0.1;
            if (scale <= 0.1) {
                scale = 0.1;
            }
        }
        drawImg();
    }

    function loadImage(input) {
        reader.onload = function (event) {
            //show canvas
            $('#crop-pop-up').fadeIn(200, function () {
                $(window).bind('wheel', scrollActionHandler);
                $('body').addClass('on-blur');
            });
            img.onload = function () {

                computeScale();
                drawImg();
                $('#ori-width').get(0).innerText = "原图宽度:" + img.width;
                $('#ori-height').get(0).innerText = "原图高度:" + img.height;
            }
            img.src = event.target.result;
        };
        if (input.files.length) {
            reader.readAsDataURL(input.files[0]);
        }
    }

    function computeScale() {
        // width first
        if (img.height * aspectRatio > img.width) {
            canvasWidth = $('#crop-canvas').width();
            canvasHeight = Math.floor(canvasWidth / aspectRatio);
        } else {
            canvasHeight = $('#crop-canvas').height();
            canvasWidth = Math.floor(canvasHeight * aspectRatio);
        }
        maxScale = new Number(canvasWidth / img.width);
        scale = maxScale;
        if (scale >= 1.0)
            scale = 1.0
        canvas.width = canvasWidth;
        canvas.height = canvasHeight;
    }

    function drawImg() {

        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.drawImage(img, 0, 0, img.width * scale, img.height * scale);
        //show scale ratio
        $("#scale-ratio").get(0).innerText = "缩放比例:" + scale.toFixed(4);
    }

    function bindActon() {

        $('.image-uploader').each(function () {
            $(this).on('change', function () {
                loadImage(this);
                inputDom = this;
            });
        });
        $('.close-pop-up').on('click', function () {
            $('#crop-pop-up').fadeOut(200, function () {
                $('body').removeClass('on-blur');
                $(window).unbind('wheel');
                scale = 1.0;
                aspectRatio = 2.0;
            });
        });

        $('#crop-reset').on('click', reset);
    }

    return {
        init: init
    }
})();
//check jquery is loaded
window.onload = function () {
    if (window.jQuery) {
        cropModule.init();
    } else {
        alert("this javascript relies on jquery !");
    }
};