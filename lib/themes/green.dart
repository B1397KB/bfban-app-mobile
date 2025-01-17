import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/index.dart';

class GreenTheme extends AppBaseThemeItem {
  @override
  init() {}

  @override
  changeSystem() {
    SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
      statusBarBrightness: Brightness.dark,
    );
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }

  @override
  get d => data;

  @override
  static dynamic data = AppThemeItem(
    name: "green",
    isDefault: false,
    themeData: ThemeData(
      sliderTheme: SliderThemeData(
        valueIndicatorColor: Colors.pink.shade50,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all(Colors.green.shade300),
          textStyle: MaterialStateProperty.all(
            TextStyle(color: Colors.green.shade300),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.green.withOpacity(.1),
        modalBackgroundColor: Colors.green.withOpacity(.1),
      ),
      canvasColor: const Color(0xFF4CAF50),
      primaryColorDark: Colors.green.shade300,
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFF5DB761)),
        displayMedium: TextStyle(color: Color(0xFF5DB761)),
        displaySmall: TextStyle(color: Color(0xFF5DB761)),
        headlineMedium: TextStyle(color: Colors.black),
        headlineSmall: TextStyle(color: Colors.black),
        titleLarge: TextStyle(color: Color(0xFF072F07)),
        titleMedium: TextStyle(color: Color(0xFF072F07)),
        titleSmall: TextStyle(color: Color(0xFF072F07)),
        bodyLarge: TextStyle(color: Color(0xFF072F07)),
        bodyMedium: TextStyle(color: Color(0xFF072F07)),
        bodySmall: TextStyle(color: Color(0xFF072F07)),
      ),
      switchTheme: const SwitchThemeData().copyWith(
        trackColor: MaterialStateProperty.all(Colors.green.shade300.withOpacity(.2)),
        thumbColor: MaterialStateProperty.all(Colors.green.shade300),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: Colors.green.shade300.withOpacity(.1),
        selectionHandleColor: Colors.green.shade300.withOpacity(.1),
        cursorColor: Colors.green.shade300,
      ),
      unselectedWidgetColor: Colors.white,
      scaffoldBackgroundColor: const Color(0xFFFCFFFC),
      splashColor: Colors.transparent,
      dialogBackgroundColor: Colors.white,
      dialogTheme: DialogTheme(
        elevation: 10,
        backgroundColor: Colors.green.shade300,
        titleTextStyle: const TextStyle(
          color: Colors.white,
        ),
      ),
      highlightColor: Colors.transparent,
      toggleButtonsTheme: ToggleButtonsThemeData(
        color: Colors.green.shade50,
        fillColor: Colors.green.shade50,
        textStyle: TextStyle(
          color: Colors.green.shade300,
        ),
        focusColor: Colors.white60,
        selectedColor: Colors.white,
        selectedBorderColor: Colors.green.shade800,
        splashColor: Colors.black38,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Colors.white,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Colors.white,
        textStyle: TextStyle(
          color: Colors.black,
        ),
        elevation: 2,
      ),
      dividerColor: Colors.green.shade50,
      dividerTheme: DividerThemeData(
        color: Colors.green.shade50,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.white)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all(
            TextStyle(
              color: Colors.green.shade300,
            ),
          ),
          elevation: MaterialStateProperty.all(0.2),
          backgroundColor: MaterialStateProperty.all(Colors.green.shade300),
          foregroundColor: MaterialStateProperty.all(Colors.white),
          visualDensity: VisualDensity.comfortable,
          shadowColor: MaterialStateProperty.all(Colors.transparent),
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          mouseCursor: MaterialStateProperty.all(MouseCursor.defer),
          enableFeedback: true,
          splashFactory: NoSplash.splashFactory,
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
              side: const BorderSide(
                color: Colors.black12,
                width: 1,
              ),
            ),
          ),
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: Colors.green.shade300,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.green.shade300,
        disabledColor: Colors.green.shade300.withOpacity(.2),
      ),
      buttonBarTheme: const ButtonBarThemeData(
        layoutBehavior: ButtonBarLayoutBehavior.constrained,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.green.shade50,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFDFD),
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
        selectedItemColor: Colors.green.shade300,
        selectedLabelStyle: TextStyle(
          color: Colors.green.shade300,
          fontSize: 14,
        ),
        elevation: 0,
        unselectedItemColor: Colors.green.shade100,
        unselectedLabelStyle: TextStyle(
          color: Colors.green.shade100,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        color: Colors.green.shade300,
        foregroundColor: Colors.white,
        shadowColor: Colors.green.shade50,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      primaryColor: Colors.green,
      tabBarTheme: TabBarTheme(
        unselectedLabelColor: Colors.green.shade100,
        labelColor: Colors.green,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: Colors.green,
            width: 3,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.green.shade300,
        focusColor: Colors.white,
      ),
      iconTheme: IconThemeData(
        color: Colors.green.shade300,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: BorderSide(
            color: Colors.green.shade50,
            width: 1,
          ),
        ),
      ),
      radioTheme: RadioThemeData(
        mouseCursor: MaterialStateProperty.all(MouseCursor.uncontrolled),
        overlayColor: MaterialStateProperty.all(Colors.green.withOpacity(.7)),
        fillColor: MaterialStateProperty.all(Colors.green),
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: MaterialStateProperty.all(Colors.white),
        fillColor: MaterialStateProperty.all(Colors.green.shade300),
        side: const BorderSide(
          color: Colors.black12,
          width: 3,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.black12,
        secondarySelectedColor: Colors.white,
        checkmarkColor: Colors.white,
        iconTheme: IconThemeData(
          color: Colors.green.shade300,
        ),
        secondaryLabelStyle: TextStyle(
          color: Colors.green.shade300,
        ),
        labelStyle: TextStyle(
          color: Colors.green.shade300,
        ),
      ),
      colorScheme: ColorScheme(
        outline: Colors.white10,
        brightness: Brightness.dark,
        primary: Colors.green.shade300,
        onPrimary: Colors.green.shade300,
        secondary: const Color(0xff0a111c),
        onSecondary: const Color(0xff0a111c),
        error: Colors.redAccent,
        onError: Colors.redAccent,
        errorContainer: Colors.white,
        background: const Color(0xff111b2b),
        onBackground: const Color(0xff111b2b),
        surface: Colors.white,
        onSurface: Colors.white,
        // background: Colors.black,
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: Color(0xFFFFFDFD),
        elevation: 0,
      ),
    ),
  );
}
