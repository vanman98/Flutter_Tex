import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:flutter_tex/src/utils/core_utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TeXViewState extends State<TeXView> with AutomaticKeepAliveClientMixin {
  WebViewController? _controller;

  double _height = minHeight;
  String? _lastData;
  bool _pageLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (message) {
            _pageLoaded = true;
            _initTeXView();
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel('TeXViewRenderedCallback',
          onMessageReceived: (jm) async {
        double height = double.parse(jm.message);
        if (_height != height) {
          setState(() {
            _height = height;
          });
        }
        widget.onRenderFinished?.call(height);
      })
      ..addJavaScriptChannel('OnTapCallback', onMessageReceived: (jm) async {
        widget.child.onTapCallback(jm.message);
      })
      ..loadFile(
          "packages/flutter_tex/js/${widget.renderingEngine?.name ?? 'katex'}/index.html");
    super.build(context);
    updateKeepAlive();
    _initTeXView();
    return IndexedStack(
      index: widget.loadingWidgetBuilder?.call(context) != null
          ? _height == minHeight
              ? 1
              : 0
          : 0,
      children: <Widget>[
        SizedBox(
          height: _height,
          child: WebViewWidget(
            controller: _controller!,
            // onPageFinished: (message) {
            //   _pageLoaded = true;
            //   _initTeXView();
            // },
            // initialUrl:
            //     "packages/flutter_tex/js/${widget.renderingEngine?.name ?? 'katex'}/index.html",
            // onWebViewCreated: (controller) {
            //   _controller = controller;
            // },
            // initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
            // backgroundColor: Colors.transparent,
            // allowsInlineMediaPlayback: true,
            // javascriptChannels: {
            //   JavascriptChannel(
            //       name: 'TeXViewRenderedCallback',
            //       onMessageReceived: (jm) async {
            //         double height = double.parse(jm.message);
            //         if (_height != height) {
            //           setState(() {
            //             _height = height;
            //           });
            //         }
            //         widget.onRenderFinished?.call(height);
            //       }),
            //   JavascriptChannel(
            //       name: 'OnTapCallback',
            //       onMessageReceived: (jm) {
            //         widget.child.onTapCallback(jm.message);
            //       })
            // },
            // javascriptMode: JavascriptMode.unrestricted,
          ),
        ),
        widget.loadingWidgetBuilder?.call(context) ?? const SizedBox.shrink()
      ],
    );
  }

  void _initTeXView() {
    if (_pageLoaded && _controller != null && getRawData(widget) != _lastData) {
      if (widget.loadingWidgetBuilder != null) _height = minHeight;
      _controller!.runJavaScript("initView(${getRawData(widget)})");
      _lastData = getRawData(widget);
    }
  }
}
