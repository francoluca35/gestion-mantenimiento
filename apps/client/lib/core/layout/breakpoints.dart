class Breakpoints {
	const Breakpoints._();

	static const double mobile = 600;
	static const double tablet = 900;
	static const double desktop = 1200;

	static bool isMobile(double width) => width < mobile;
	static bool isDesktop(double width) => width >= tablet;
}
