/**
 * Created by mi on 9/12/16.
 */
var cropModule = (function () {
    //img reader
    var reader = new FileReader();
    //img
    var img = new Image();
    var canvas, ctx;
    //
    function init() {
        appendDom();
        canvas = $('#crop-canvas')[0];
        ctx = canvas.getContext("2d");
        bindActon();
    }

    function appendDom() {
        var cropPopUpCss = "<style type='text/css'>" +
            ".not-display{ display:none;} " +
            "#crop-pop-up{ position: fixed;top: 10%;left: 15%;width: 70% ;height: 70%;z - index:1000;border: solid 2px;background: white;}" +
            ".on-blur {background-color:gray}" +
            "#crop-canvas { display : inline-block ; float : left;padding : 20px }" +
            "#crop-options { display : inline-block ; float:right; margin-right: 25px; margin-top: 25px }" +
            ".close-pop-up {float:right;margin-top:-10px;margin-right:-10px;cursor:pointer;color:#fff;border: 1px solid #AEAEAE;border-radius: 30px;background: #605F61;font-size: 31px;font-weight: bold;display: inline-block;line-height: 0px;padding: 11px 3px; } " +
            ".close-pop-up:before{ content : '×' }" +
            "</style>";

        var cropPopUpTemplate = "<div class='not-display' id='crop-pop-up'>" +
            "<div><a class='close-pop-up'></a></div>" +
            "<canvas id='crop-canvas'></canvas>" +
            "<div id='crop-options'>" +
            "<div id='ori-width'></div>" +
            "<div id='ori-height'></div>" +
            "<hr>" +
            "</div>" +
            "</div>"

        var cssDom = $.parseHTML(cropPopUpCss);
        var templateDom = $.parseHTML(cropPopUpTemplate);
        //append css
        $('head').append(cssDom);
        //append template
        $('body').append(templateDom);
    }

    function loadImage(input) {
        reader.onload = function (event) {
            //show canvas
            $('#crop-pop-up').fadeIn(200, function () {
                $('body').addClass('on-blur');
            });
            img.onload = function () {
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

    function drawImg() {
        canvas.width = 400;
        canvas.height = 180;

        ctx.drawImage(img, 0, 0, img.width * 0.4, img.height * 0.4);
    }

    function bindActon() {

        $('.image-uploader').each(function () {
            $(this).on('change', function () {
                loadImage(this);
            });
        });

        $('.close-pop-up').on('click', function () {
            $('#crop-pop-up').fadeOut(200, function () {
                $('body').removeClass('on-blur');
            });
        });
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