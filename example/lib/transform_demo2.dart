import 'package:flutter/material.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class TransformDemo2 extends StatefulWidget {
  @override
  _TransformDemo2State createState() => _TransformDemo2State();
}

class _TransformDemo2State extends State<TransformDemo2> {
  Matrix4 matrix;
  ValueNotifier<Matrix4> notifier;
  Boxer boxer;

  @override
  void initState() {
    super.initState();
    matrix = Matrix4.identity();
    notifier = ValueNotifier(matrix);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TransformDemo Demo 2'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          // get the width and height of the layout (device)
          var width = constraints.biggest.width;
          var height = constraints.biggest.height;
          // build the box to be bounded within the device and to be half the area of the device

          boxer = Boxer(Offset.zero & constraints.biggest,
              Rect.fromLTWH(0, 0, width, height));

          // boxer = Boxer(Offset.zero & constraints.biggest,
          //     Rect.fromLTWH(0, 0, width, height));

          // start the Container in the middle of the layout
          // (this won't be run for hot reload)
          // var dx = (constraints.biggest.width - width) / 2;
          // var dy = (constraints.biggest.height - height) / 2;
          // matrix.leftTranslate(dx, dy);

          return MatrixGestureDetector(
            shouldRotate: false,
            onMatrixUpdate: (m, translationDeltaMatrix, scaleDeltaMatrix,
                rotationDeltaMatrix) {
              // build the matrix that the Transform will use
              matrix = MatrixGestureDetector.compose(
                  matrix, translationDeltaMatrix, scaleDeltaMatrix, null);

              // clamp the matrix within the constraints
              boxer.clamp(matrix);

              // apply the change to the notifier
              notifier.value = matrix;
            },
            child: Container(
              // width: double.infinity,
              // height: double.infinity,
              // alignment: Alignment.topLeft,
              color: Colors.deepPurple,
              child: AnimatedBuilder(
                builder: (ctx, child) {
                  return Transform(
                    transform: notifier.value,
                    child: Container(
                      // width: width,
                      // height: height,
                      decoration: BoxDecoration(
                          color: Colors.white30,
                          border: Border.all(
                            color: Colors.black45,
                            width: 20,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      child: Center(
                          child: MapStack(
                              area: boxer.clamp(notifier.value).width *
                                  boxer.clamp(notifier.value).height,
                              regionImage: Image.asset('assets/region.png'),
                              subregionImage:
                                  Image.asset('assets/subregion.png'))),
                    ),
                  );
                },
                animation: notifier,
              ),
            ),
          );
        },
      ),
    );
  }
}

class Boxer {
  final Rect bounds;
  final Rect src;
  Rect dst;

  // the bounding rectangle and the previous (or initial) rectangle
  Boxer(this.bounds, this.src);

  Rect clamp(Matrix4 m) {
    // build a new candidate rectangle from the old rectangle after doing the given matrix transform
    dst = MatrixUtils.transformRect(m, src);
    if (bounds.left >= dst.left &&
        bounds.top >= dst.top &&
        bounds.right <= dst.right &&
        bounds.bottom <= dst.bottom) {
      // bounds contains destination rect
      return dst;
    }

    // deal with scaling out of the bounds
    // if (dst.width > bounds.width || dst.height > bounds.height) {
    //   // the intersection is the overlap are of the two rectangles
    //   Rect intersected = dst.intersect(bounds);
    //   FittedSizes fs = applyBoxFit(BoxFit.contain, dst.size, intersected.size);

    //   vector.Vector3 t = vector.Vector3.zero();
    //   intersected = Alignment.center.inscribe(fs.destination, intersected);
    //   if (dst.width > bounds.width)
    //     t.y = intersected.top;
    //   else
    //     t.x = intersected.left;

    //   var scale = fs.destination.width / src.width;
    //   vector.Vector3 s = vector.Vector3(scale, scale, 0);
    //   m.setFromTranslationRotationScale(t, vector.Quaternion.identity(), s);
    //   return;
    // }

    // deal with translating out of the bounds
    if (dst.left > bounds.left) {
      // if the destination rect is too far right,
      // modify the translate matrix to move it to the left (negative dx)
      // by the difference between the left sides of dest and bound
      print('tried to go too far right');
      m.leftTranslate(bounds.left - dst.left, 0.0);
    }
    if (dst.top > bounds.top) {
      print('tried to go too far down');

      m.leftTranslate(0.0, bounds.top - dst.top);
    }
    if (dst.right < bounds.right) {
      print('tried to go too far left');

      m.leftTranslate(bounds.right - dst.right, 0.0);
    }
    if (dst.bottom < bounds.bottom) {
      print('tried to go too far up');

      m.leftTranslate(0.0, bounds.bottom - dst.bottom);
    }

    // return for use by region/subregion area
    return dst;
  }
}

// A full screen Stack for a map image
class MapStack extends StatefulWidget {
  final Key key;
  final double area;
  final Image regionImage;
  final Image subregionImage;

  MapStack({
    this.key,
    this.area,
    @required this.regionImage,
    @required this.subregionImage,
  }) : super(key: key);

  @override
  MapStackState createState() => MapStackState();
}

class MapStackState extends State<MapStack>
    with SingleTickerProviderStateMixin {
  AnimationController _fadeController;
  Animation _fadeInAnimation;
  Animation _fadeOutAnimation;
  double scale = 0.1;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _fadeInAnimation = Tween(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeOutAnimation = Tween(begin: 1.0, end: 0.0).animate(_fadeController);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.area > 2000000) {
      _fadeController.forward();
    }
    if (widget.area <= 2000000) {
      _fadeController.reverse();
    }
    return Stack(
      children: <Widget>[
        positionedFadeImage(image: widget.regionImage, isSubregion: false),
        positionedFadeImage(image: widget.subregionImage, isSubregion: true)
      ],
    );
  }

  Widget positionedFadeImage(
      {@required Image image, @required bool isSubregion}) {
    return Positioned(
      child: FadeTransition(
          opacity: isSubregion ? _fadeInAnimation : _fadeOutAnimation,
          child: image),
      // ),
    );
  }
}
