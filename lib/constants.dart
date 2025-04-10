// File: lib/constants.dart
// Location: ./lib/constants.dart

// --- Website ---
const baseDomain = "http://www.alpentor.com/rainboku";

// --- Grid & Game Logic ---
const int kGridSize = 9; // Standard Sudoku grid dimension (9x9)
const int kBoxSize = 3; // Standard Sudoku box dimension (3x3)
const int kPaletteSize = 9; // Number of colors/options in the game palette
const int kMaxHistory = 20; // Maximum number of undo steps to store

// Number of cells to remove for puzzle generation based on difficulty
const int kDifficultyEasyCellsToRemove = 25;
const int kDifficultyMediumCellsToRemove = 38;
const int kDifficultyHardCellsToRemove = 47;
const int kDifficultyPainfulCellsToRemove = 53; // Corresponds to 'Painful' difficulty

// --- Durations & Delays ---
// General UI Animations
const Duration kShortAnimationDuration = Duration(milliseconds: 150); // For quick transitions like AnimatedContainer
const Duration kMediumAnimationDuration = Duration(milliseconds: 500); // For standard animations like cell placement

// Specific Feature Animations
const Duration kHighlightAnimationDuration = Duration(milliseconds: 500); // Duration for control button highlight pulse-in
const Duration kHighlightReverseDuration = Duration(milliseconds: 1000); // Duration for control button highlight fade-out
const Duration kHighlightHoldDuration = Duration(milliseconds: 2500); // How long the highlight stays active
const Duration kNumberFadeDuration = Duration(milliseconds: 1500); // Duration for intro number fade-in
const Duration kNumberFadeReverseDuration = Duration(milliseconds: 1300); // Duration for intro number fade-out
const Duration kIntroSequenceDelay = Duration(milliseconds: 2000); // Delay before starting intro number fade/highlight sequence
const Duration kIntroHighlightDelay = Duration(milliseconds: 1200); // Delay after number fade starts before triggering highlight (1600ms fade + 100ms buffer)
const Duration kConfettiDuration = Duration(seconds: 2); // How long the completion confetti animation runs
const Duration kSnackbarDuration = Duration(seconds: 2); // How long snackbar messages are displayed

// Timers & Intervals
const Duration kTimerUpdateInterval = Duration(seconds: 1); // How often the game timer updates its display
const int kIntroPlacementDelayMultiplier = 100; // Milliseconds per cell index (row+col) for staggered placement animation
const int kIntroFadeDelayMultiplier = 50; // Milliseconds per cell index (row+col) for staggered number fade animation

// --- Sizes & Dimensions ---
// Radii for rounded corners
const double kSmallRadius = 8.0; // e.g., TextFields, small buttons
const double kMediumRadius = 16.0; // e.g., Dialogs, cards, FABs, palette container
const double kLargeRadius = 20.0; // e.g., Modal bottom sheet
const double kCellCornerRadius = 6.0; // Rounded corners for individual Sudoku cells
const double kGridCornerRadius = 8.0; // Rounded corners for the main Sudoku grid container

// Specific Widget Sizes
const double kPaletteCircleSize = 40.0; // Diameter of the color selection circles
const double kCandidateDotMinSize = 4.0; // Minimum size of the small candidate dots in a cell
const double kCandidateDotMaxSize = 8.0; // Maximum size of the small candidate dots in a cell
const double kSmallIconSize = 15.0; // Size of the small color squares in the settings palette chooser
const double kGrabHandleWidth = 40.0; // Width of the drag handle on the settings modal sheet
const double kGrabHandleHeight = 5.0; // Height of the drag handle on the settings modal sheet

// --- Padding & Spacing ---
// General Padding Values
const double kDefaultPadding = 8.0;
const double kMediumPadding = 12.0;
const double kLargePadding = 16.0;
const double kExtraLargePadding = 20.0;
const double kGridPadding = 2.0; // Padding around the Sudoku grid view inside its border

// Spacing between Widgets (e.g., SizedBox heights/widths)
const double kSmallSpacing = 8.0;
const double kMediumSpacing = 10.0;
const double kLargeSpacing = 15.0;
const double kExtraLargeSpacing = 20.0;
const double kHugeSpacing = 30.0;
const double kMassiveSpacing = 40.0;

// Specific Layout Spacing
const double kCandidateGridSpacing = 1.0; // Spacing between candidate dots within a cell
const double kCandidatePadding = 1.5; // Padding around the grid of candidate dots

// --- Font Sizes ---
const double kDefaultFontSizeConst = 18.0; // Default font size for buttons, standard text
const double kMediumFontSize = 17.0; // Slightly smaller font size, e.g., for palette item numbers
const double kLargeFontSize = 20.0; // Larger font size, e.g., for AppBar titles

// --- Elevation ---
const double kDefaultElevation = 2.0; // Standard elevation for floating elements
const double kHighElevation = 3.0; // Slightly higher elevation for emphasized elements (e.g., main buttons)

// --- Borders ---
const double kDefaultBorderWidth = 1.0; // Default width for borders
const double kThinGridBorderWidth = 0.6; // Width for the thin lines inside the Sudoku grid
const double kThickGridBorderWidth = 1.0; // Width for the thick lines separating 3x3 boxes in the grid
const double kOuterGridBorderWidth = 1.5; // Width for the border around the entire Sudoku grid
const double kSelectedCellBorderWidth = 3.0; // Width of the border highlight for the selected cell
const double kErrorCellBorderWidth = 2.5; // Width of the border indicating a cell error
const double kCandidateDotBorderWidth = 0.5; // Width of the border around candidate dots

// --- Opacities & Colors (Commonly used fractional values) ---
const double kLowOpacity = 0.1;         // Very low opacity (10%)
const double kMediumLowOpacity = 0.15;  // Medium-low opacity (15%)
const double kLowMediumOpacity = 0.2;   // Low-medium opacity (20%)
const double kMediumOpacity = 0.3;      // Medium opacity (30%)
const double kHighMediumOpacity = 0.5;  // High-medium opacity (50%)
const double kMediumHighOpacity = 0.7;  // Medium-high opacity (70%)
const double kHighOpacity = 0.8;        // High opacity (80%)
const double kVeryHighOpacity = 0.9;    // Very high opacity (90%)
const double kMaxOpacity = 1.0;         // Full opacity (100%)
const double kGlassEffectOpacity = 0.15;// Base opacity for glassmorphism background effect
const double kDimmedOpacity = 0.3;      // Opacity for dimmed/disabled elements like palette items

// --- Layout Constraints ---
const double kControlMaxWidth = 350.0;  // Max width for the game controls row
const double kHomeMaxWidth = 325.0;     // Max width for the difficulty selection container on home screen
const double kPaletteMaxWidth = 350.0;  // Max width for the palette selector container

// --- Animation Values ---
const double kHighlightScaleEnd = 1.15; // Target scale factor for the highlight animation
const double kHighlightScaleStart = 1.0; // Starting scale factor for the highlight animation

// --- Bokeh & Effects ---
const int kBokehParticleCount = 12; // Number of bokeh particles for the background effect
const double kBokehBlurSigma = 4.0;  // Sigma value for the blur effect applied to bokeh particles
const double kBokehMaxRadiusFactor = 0.10; // Max particle radius as a factor of screen width
const double kBokehMinRadiusFactor = 0.015; // Min particle radius as a factor of screen width
const double kBokehMaxVelocity = 0.5; // Max velocity for drifting bokeh particles

// --- Patterns ---
const double kPatternPaddingFactor = 0.2; // Padding inside the cell boundary for drawing patterns (20% on each side)
const double kPatternStrokeMultiplier = 0.06; // Stroke width for patterns as a multiplier of cell size

// --- Confetti ---
const int kConfettiParticleCount = 20; // Number of confetti particles per emission burst
const double kConfettiGravity = 0.1; // Downward force applied to confetti particles
const double kConfettiEmissionFrequency = 0.03; // How often confetti bursts occur (0 = never, 1 = constantly)
const double kConfettiMaxBlastForce = 20.0; // Maximum initial force applied to confetti particles
const double kConfettiMinBlastForce = 8.0; // Minimum initial force applied to confetti particles
const double kConfettiParticleDrag = 0.05; // Air resistance factor applied to confetti particles