import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../pizzule_path.dart';
import 'slider_captcha_components.dart';

class SliderController {
  late Offset? Function() create;
}

class SliderCaptcha extends StatefulWidget {
  const SliderCaptcha({
    Key? key,
    required this.image,
    this.onConfirm,
    this.controller,
    this.label = 'Slide to authenticate',
    this.labelStyle,
    this.sliderColor = Colors.red,
    this.puzzleColor = Colors.blue,
    // this.captchaSize,
    this.imageToBarPadding = 0,
    this.borderImager = 0,
  })  : assert(!(onConfirm == null && controller == null),
            'Must provide one of either controller or onConfirm'),
        assert((onConfirm != null) ^ (controller != null),
            'Cannot provide both controller and onConfirm callback.'),
        super(key: key);

  final Image image;

  final SliderCaptchaController? controller;

  final Future<void> Function(bool value)? onConfirm;

  final String label;

  final TextStyle? labelStyle;

  final Color sliderColor;

  final Color puzzleColor;

  /// Adds space between the captcha image and the slide button bar.
  /// Defaults is 0
  final double imageToBarPadding;

  /// to make sure no problems arise, borderImage only allows sheet limit 0 -> 5
  final double borderImager;

  @override
  State<SliderCaptcha> createState() => _SliderCaptchaState();
}

class _SliderCaptchaState extends State<SliderCaptcha> {
  late SliderCaptchaController _controller;
  @override
  void initState() {
    _controller =
        widget.controller ?? SliderCaptchaController(widget.onConfirm!);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SliderCaptchaPuzzle(
            controller: _controller,
            image: widget.image,
            puzzleColor: widget.puzzleColor,
            borderRadius: BorderRadius.circular(widget.borderImager),
          ),
        ),
        SizedBox(height: widget.imageToBarPadding),
        SliderCaptchaButton(
          controller: _controller,
          sliderColor: widget.sliderColor,
          thumbSize: 50,
          label: widget.label,
          labelStyle: widget.labelStyle,
        ),
      ],
    );
  }
}

class TestSliderCaptChar extends SingleChildRenderObjectWidget {
  ///Hình ảnh góc
  final Image image;

  /// Vị trí dx slider captChar
  final double offsetX;

  /// Vị trí dy slider captChar
  final double offsetY;

  /// Màu sắt của captchar
  final Color colorCaptChar;

  /// Kích thước của captchar
  final double sizeCaptChar;

  final SliderController sliderController;

  const TestSliderCaptChar(
    this.image,
    this.offsetX,
    this.offsetY, {
    this.sizeCaptChar = 40,
    this.colorCaptChar = Colors.blue,
    required this.sliderController,
    Key? key,
  }) : super(key: key, child: image);

  @override
  RenderObject createRenderObject(BuildContext context) {
    final renderObject = _RenderTestSliderCaptChar();
    renderObject.offsetX = offsetX;
    renderObject.offsetY = offsetY;
    renderObject.colorCaptChar = colorCaptChar;
    renderObject.sizeCaptChar = sizeCaptChar;
    renderObject.colorCaptChar = colorCaptChar;
    sliderController.create = renderObject.create;
    return renderObject;
  }

  // //
  @override
  void updateRenderObject(context, _RenderTestSliderCaptChar renderObject) {
    renderObject.offsetX = offsetX;
    renderObject.offsetY = offsetY;
    renderObject.colorCaptChar = colorCaptChar;
    renderObject.sizeCaptChar = sizeCaptChar;
    renderObject.colorCaptChar = colorCaptChar;

    super.updateRenderObject(context, renderObject);
  }
}

class _RenderTestSliderCaptChar extends RenderProxyBox {
  /// Kích thước của khối bloc
  double sizeCaptChar = 40;

  /// Kích thước của viền ngoài khối block
  double strokeWidth = 3;

  /// Vị trí đỉnh [dx] của puzzle block
  double offsetX = 0;

  /// Vị trí đỉnh [dy] của puzzle block
  double offsetY = 0;

  /// kết quả: dx
  double createX = 0;

  /// kết quả: dy
  double createY = 0;

  /// màu sắc của khối bloc
  Color colorCaptChar = Colors.black;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    /// Vẽ hình background.
    context.paintChild(child!, offset);

    /// Khử trường hợp ảnh bị giật khi sử dụng WidgetsBinding.instance.addPostFrameCallback
    if (!(child!.size.width > 0 && child!.size.height > 0)) {
      return;
    }

    Paint paint = Paint()
      ..color = colorCaptChar
      ..strokeWidth = strokeWidth;

    if (createX == 0 && createY == 0) return;

    context.canvas.drawPath(
      getPiecePathCustom(
        size,
        strokeWidth + offset.dx + createX.toDouble(),
        offset.dy + createY.toDouble(),
        sizeCaptChar,
      ),
      paint..style = PaintingStyle.fill,
    );

    context.canvas.drawPath(
      getPiecePathCustom(
        Size(size.width - strokeWidth, size.height - strokeWidth),
        strokeWidth + offset.dx + offsetX,
        offset.dy + createY,
        sizeCaptChar,
      ),
      paint..style = PaintingStyle.stroke,
    );

    layer = context.pushClipPath(
      needsCompositing,

      /// Move về đầu [-create] và trược theo offsetX
      Offset(-createX + offsetX + offset.dx + strokeWidth, offset.dy),
      Offset.zero & size,
      getPiecePathCustom(
        size,
        createX,
        createY.toDouble(),
        sizeCaptChar,
      ),
      (context, offset) {
        context.paintChild(child!, offset);
      },
      oldLayer: layer as ClipPathLayer?,
    );
  }

  @override
  void performLayout() {
    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //   /// tam fix
    //   if (createX != 0 && createY != 0) return;
    //   create();
    //   markNeedsPaint();
    // });

    super.performLayout();
  }

  /// Hàm khởi tạo kết quả của khối bloc
  Offset? create() {
    if (size == Size.zero) {
      return null;
    }
    createX = sizeCaptChar +
        Random().nextInt((size.width - 2.5 * sizeCaptChar).toInt());

    createY = 0.0 + Random().nextInt((size.height - sizeCaptChar).toInt());

    markNeedsPaint();

    return Offset(createX, createY);
  }
}
