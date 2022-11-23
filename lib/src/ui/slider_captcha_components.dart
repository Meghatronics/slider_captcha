import 'package:flutter/material.dart';

import '../../slider_capchar.dart';

//! CONTROLLER ______________________________
class SliderCaptchaController extends ValueNotifier<double> {
  SliderCaptchaController(
    this.onConfirm, {
    this.resetPuzzleAfterError = true,
  }) : super(0);
  final ValueSetter<bool> onConfirm;
  final bool resetPuzzleAfterError;
  var _sliderController = SliderController();

  bool _locked = false;
  late double _answer;
  double? _answerOnCrossAxis;

  double get answerY => _answerOnCrossAxis ?? 0;
  SliderController get sliderController => _sliderController;

  void _initialise() async {
    await Future.delayed(Duration(milliseconds: 150));
    final offset = sliderController.create();
    _answer = offset?.dx ?? 0;
    _answerOnCrossAxis = offset?.dy ?? 0;
  }

  void reset() {
    _sliderController = SliderController();
    value = 0;
  }

  void _thumbDragStart(
    BuildContext context,
    DragStartDetails start,
    double thumbSize,
  ) {
    if (_locked) return;
    RenderBox getBox = context.findRenderObject() as RenderBox;
    var local = getBox.globalToLocal(start.globalPosition);

    value = local.dx - (thumbSize / 2);
  }

  void _thumbDragUpdate(
    BuildContext context,
    DragUpdateDetails update,
    double thumbSize,
  ) {
    if (_locked) return;
    RenderBox getBox = context.findRenderObject() as RenderBox;
    var local = getBox.globalToLocal(update.globalPosition);

    if (local.dx < 0) {
      value = 0;
      return;
    }

    if (local.dx > getBox.size.width) {
      value = getBox.size.width - thumbSize;
      return;
    }

    value = local.dx - (thumbSize / 2);
  }

  void _thumbDragEnd() {
    if (_locked) return;
    _locked = true;

    final answerIsWithinCorrectRange =
        value < _answer + 10 && value > _answer - 10;

    onConfirm(answerIsWithinCorrectRange);
    if (resetPuzzleAfterError && !answerIsWithinCorrectRange) reset();

    _locked = false;
  }
}

//! PUZZLE WIDGET ______________________________
class SliderCaptchaPuzzle extends StatefulWidget {
  SliderCaptchaPuzzle({
    required this.controller,
    required this.image,
    this.puzzleColor = Colors.blue,
    this.borderRadius = BorderRadius.zero,
  }) : super(key: ObjectKey(controller.sliderController));

  final SliderCaptchaController controller;
  final Image image;
  final Color puzzleColor;
  final BorderRadius borderRadius;

  @override
  State<SliderCaptchaPuzzle> createState() => _SliderCaptchaPuzzleState();
}

class _SliderCaptchaPuzzleState extends State<SliderCaptchaPuzzle> {
  @override
  void initState() {
    super.initState();
  }

  WidgetsBinding? _widgetsBinding() => WidgetsBinding.instance;

  @override
  void didChangeDependencies() {
    _widgetsBinding()?.addPostFrameCallback((_) {
      widget.controller._initialise();
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.controller,
      builder: (__, offset, _) => ClipRRect(
        borderRadius: widget.borderRadius,
        child: TestSliderCaptChar(
          widget.image,
          offset,
          widget.controller.answerY,
          colorCaptChar: widget.puzzleColor,
          sliderController: widget.controller.sliderController,
          key: ObjectKey(widget.controller.sliderController),
        ),
      ),
    );
  }
}

//! SLIDE BUTTON WIDGET _______________________________
class SliderCaptchaButton extends StatelessWidget {
  const SliderCaptchaButton({
    required this.controller,
    this.label = 'Slide to authenticate',
    Key? key,
    this.slider,
    this.thumbSize = 50,
    this.sliderColor = Colors.red,
    this.thumb,
    this.labelStyle,
  }) : super(key: key);

  final SliderCaptchaController controller;
  final String label;
  final double thumbSize;
  final Color sliderColor;
  final TextStyle? labelStyle;
  final Widget? slider;
  final Widget? thumb;

  @override
  Widget build(BuildContext context) {
    final thumb = this.thumb ??
        Container(
          height: thumbSize,
          width: thumbSize,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.white,
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Colors.grey, blurRadius: 4)
            ],
          ),
          child: const Icon(Icons.arrow_forward_rounded),
        );

    final slider = this.slider ??
        Container(
          height: thumbSize,
           decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            color: sliderColor,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: labelStyle,
            textAlign: TextAlign.center,
          ),
        );
    return SizedBox(
      height: thumbSize,
      width: double.infinity,
      child: ValueListenableBuilder<double>(
        valueListenable: controller,
        builder: (__, offset, _) => Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              right: 0,
              child: slider,
            ),
            Positioned(
              left: offset,
              height: thumbSize,
              width: thumbSize,
              child: GestureDetector(
                child: thumb,
                onHorizontalDragStart: (detail) =>
                    controller._thumbDragStart(context, detail, thumbSize),
                onHorizontalDragUpdate: (detail) =>
                    controller._thumbDragUpdate(context, detail, thumbSize),
                onHorizontalDragEnd: (detail) => controller._thumbDragEnd(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
