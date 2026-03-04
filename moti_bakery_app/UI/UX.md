
MOTIBAKERY
Flutter Application
UI / UX Design Specification

Design Style
Bold Modern - White, Strong Orange
Platform
Android (Flutter APK)
Roles Covered
Counter & Cake Room
Phase
Phase 1 - MVP
Document Version
v1.0


1. Design Philosophy & Principles

The Motibakery app follows a Bold Modern design language - clean white backgrounds, strong orange brand color, punchy typography, and smooth animations. Every screen is built to work in two modes simultaneously: impressive enough to show a customer, fast enough for a staff member to operate under counter pressure.

1.1  Core Design Principles
Principle
What It Means in Practice
Bold & Confident
Orange is used strongly - not sparingly. CTAs, icons, accents, and key data all use brand orange.
White Space First
Generous padding and clean negative space. No cluttered screens. Every element breathes.
Touch-Optimised
Minimum 48x48dp tap targets. No small text links. Designed for fingers, not cursors.
Speed & Clarity
Critical info (cake name, price, status) is always the biggest element on screen.
Premium Feel
Smooth animations on every transition. Lottie on success moments. Hero transitions on gallery.
Role Clarity
Counter and Cake Room screens have distinct visual signatures - no confusion about which mode you are in.

1.2  What Makes It Premium
• Hero image transitions - cake card flies into detail screen (built-in Flutter Hero)
• Staggered list animations - gallery cards appear with 60ms delay each (flutter_animate)
• Lottie success animation - cake + confetti plays for 2.5s after order is placed
• Glassmorphism bottom sheets - frosted glass modals for order confirmation and status update
• Haptic feedback - light vibration on button tap, success vibration on order placed
• Shimmer loading - skeleton cards pulse while gallery loads (never a spinner on main screens)
• Micro-animations - price counter animates up/down as weight slider moves
• Page transitions - shared axis (horizontal) between gallery screens, fade-through between tabs



2. Design Tokens - Color, Typography, Spacing

2.1  Color System
The palette is deliberately restrained. White does the heavy lifting. Orange does the talking.

Token Name
Hex Value
Usage
primary
#D94F1E
Primary buttons, active states, key icons, price display, tab indicators
primaryLight
#F28B5B
Hover states, secondary highlights, badge backgrounds
primaryPale
#FFF0EB
Card backgrounds on active states, info boxes, input focus fill
background
#FFFFFF
All screen backgrounds - always white
surface
#FAFAFA
Card surfaces, sheet surfaces, slightly off-white
surfaceGray
#F4F4F4
Section headers, disabled inputs, skeleton loading
textPrimary
#1C1C1C
All headings and primary body text
textSecondary
#4A4A4A
Sub-labels, descriptions, supporting text
textHint
#9E9E9E
Placeholders, timestamps, captions
borderLight
#E8E8E8
Card borders, dividers, input outlines at rest
borderFocus
#D94F1E
Input border on focus - always orange
statusNew
#9E9E9E + #F4F4F4
New order badge - grey pill
statusProgress
#1565C0 + #E3F2FD
In Progress badge - blue pill
statusPrepared
#2E7D32 + #E8F5E9
Prepared badge - green pill
error
#C62828
Error messages, validation errors
warning
#E65100
Urgency indicators, overdue delivery dates

2.2  Typography System
Font: Inter (Google Fonts). Pairs modern clarity with excellent screen legibility. Fall back to SF Pro on iOS if ever ported.

Style Token
Size
Weight
Line Height
Usage
displayLarge
28sp
Bold 700
1.15
Order confirmed heading, success screens
displayMedium
24sp
SemiBold 600
1.2
Screen titles, cake name on detail screen
headingLarge
20sp
SemiBold 600
1.3
Section headers, card headings
headingMedium
18sp
Medium 500
1.35
Sub-section headers, order ID
bodyLarge
16sp
Regular 400
1.5
Primary body text, descriptions, notes
bodyMedium
14sp
Regular 400
1.55
Secondary text, order detail lines
bodySmall
12sp
Regular 400
1.6
Timestamps, captions, helper text
labelLarge
16sp
SemiBold 600
1.0
Button labels, tab labels
labelMedium
13sp
Medium 500
1.0
Badge text, chip labels, filter text
priceDisplay
26sp
Bold 700
1.0
Total price in order form - always orange
monoSmall
13sp
Regular 400
1.4
Order IDs (monospace for alignment)

2.3  Spacing System (8dp Grid)
All spacing follows an 8dp base grid. No arbitrary values.

Token
Value
Usage
spacing2
2dp
Border widths, divider thickness
spacing4
4dp
Icon-to-label gap, chip internal vertical
spacing8
8dp
Tight gaps - icon to text, badge internal padding
spacing12
12dp
Card internal tight spacing
spacing16
16dp
Standard element gap, card padding (horizontal)
spacing20
20dp
Section padding start, list item vertical padding
spacing24
24dp
Card padding (all sides), modal horizontal margin
spacing32
32dp
Section vertical spacing, large gap between groups
spacing48
48dp
Screen top padding (below app bar), large section gap
spacing64
64dp
Between major page sections, hero image to content

2.4  Border Radius System
Token
Value
Usage
radiusXS
4dp
Chips, badges, small tags
radiusSM
8dp
Input fields, small cards
radiusMD
12dp
Standard cards, bottom sheets
radiusLG
16dp
Cake gallery cards, feature cards
radiusXL
24dp
Modals, full bottom sheets
radiusFull
100dp
Buttons (primary CTA), avatar, round icon buttons



3. Component Library

All components are built once and reused across every screen. This section defines exact measurements, states, and behaviour for each component.

3.1  Primary Button
Height
52dp
Border Radius
100dp (fully rounded pill)
Background
#D94F1E (primary orange)
Text
White, 16sp, SemiBold
Padding
0dp vertical, 24dp horizontal
Width
Full width in forms, wrap content in inline use
Shadow
0dp offset, 4dp blur, 15% orange opacity
Pressed State
Scale down to 0.97, darken bg to #B83E12
Loading State
CircularProgressIndicator (white, 20dp) replaces label
Disabled State
40% opacity, not clickable
Animation
ScaleTransition 120ms ease-out on press

Visual States
Default
Background: #D94F1E
Label: White 16sp SemiBold
Shadow: subtle orange glow


Loading
Background: #D94F1E (unchanged)
Shows white spinner - 20dp
Button not clickable during load


Disabled
Background: #D94F1E at 40% opacity
Pointer events disabled




3.2  Secondary / Outline Button
Height
52dp
Border Radius
100dp
Background
Transparent / White
Border
1.5dp, #D94F1E
Text
#D94F1E, 16sp, SemiBold
Usage
Cancel actions, secondary CTAs, 'View My Orders' on confirmation
Pressed State
Background fills to #FFF0EB


3.3  Status Badge
Used on every order card and detail screen. Pill-shaped, colour-coded.

Status
Background
Text Color
Text
Icon
New
#F4F4F4 (surface gray)
#9E9E9E
New
clock icon
In Progress
#E3F2FD (blue pale)
#1565C0
In Progress
fire icon
Prepared
#E8F5E9 (green pale)
#2E7D32
Prepared
checkmark icon

• Size: 13sp Medium, 6dp vertical padding, 12dp horizontal padding
• Border radius: 100dp
• Icon: 14dp, same colour as text, 4dp gap from text
• Animation: when status changes, badge fades out and new badge fades + scales in (200ms)


3.4  Cake Gallery Card
Width
Fills 50% grid column minus 8dp gap
Border Radius
16dp
Background
#FFFFFF with 1dp #E8E8E8 border
Shadow
0 2dp 8dp rgba(0,0,0,0.06)
Image Height
AspectRatio 4:3, cover fit, rounded top corners (16dp)
Cake Name
16sp SemiBold, #1C1C1C, max 2 lines with ellipsis
Weight Range
12sp Regular, #9E9E9E - e.g. '0.5 kg - 3 kg'
Base Rate
14sp SemiBold, #D94F1E - e.g. '₹350/kg'
Padding (text)
12dp all sides
Tap Feedback
Card scales to 0.97 + shadow deepens on press (Hero transition starts)
Entry Animation
SlideY + FadeIn, 60ms stagger per card (flutter_animate)
Inactive Badge
If cake is inactive - grey 'Unavailable' overlay on image (Admin only)


3.5  Input Field
Height
56dp (single line)
Border Radius
8dp
Border at Rest
1dp #E8E8E8
Border on Focus
2dp #D94F1E
Background
#FFFFFF at rest, #FFF0EB on focus (very subtle)
Label
Floating label - 16sp at rest, 12sp floated (orange when focused)
Hint Text
14sp, #9E9E9E
Input Text
16sp Regular, #1C1C1C
Error State
2dp red border, red label, error message 12sp below
Prefix Icon
20dp icon, #9E9E9E at rest, #D94F1E on focus
Multi-line
120dp min height (notes field), expands up to 200dp
Animation
Label float is 150ms ease curve, border color 200ms ease


3.6  App Bar
Height
56dp + status bar height
Background
#FFFFFF with 1dp bottom border #E8E8E8
Logo / Title
Left-aligned, 'moti' in brand orange 22sp Bold + 'bakery' 16sp Regular
Back Button
20dp chevron icon, #1C1C1C, 48dp tap target
Action Icons
Right side - 24dp icons, #1C1C1C, 48dp tap targets
Elevation
0dp at rest, 2dp shadow appears on scroll (animated)
Cake Room Bar
Same structure, but has distinct title 'Cake Room' in dark to differentiate role


3.7  Bottom Navigation (Counter)
Height
56dp + bottom inset
Background
#FFFFFF with 1dp top border #E8E8E8
Items
2 items: Gallery (cake icon) + My Orders (clipboard icon)
Active Item
Icon + label in #D94F1E, indicator dot below icon
Inactive
Icon + label in #9E9E9E
Animation
Icon scales 1.0 → 1.2 on select with spring curve (200ms)
Label
12sp Medium below icon
Badge
Red dot on Orders tab when a new 'Prepared' notification arrives



4. Screen-by-Screen UI Specification

4.1  Login Screen

LOGIN SCREEN
- - -
9:41  ●●●●●  WiFi  🔋

🎂
moti BAKERY
Sign in to your account


Email address
counter@motibakery.com

Password
••••••••••

Sign In

Accounts managed by Admin only
< Home  |  Recents

Measurements
Logo area
Vertically centered at top 35% of screen
Logo size
80dp × 80dp icon, 28sp brand name below
Top padding
64dp from status bar to logo top
Form padding
24dp horizontal, 32dp below logo
Field gap
16dp between fields
Button margin
24dp top from last field
Tagline
12sp, #9E9E9E, centred below button

Animation Sequence
• Logo fades + slides up (300ms, delay 0ms)
• Email field fades in (250ms, delay 150ms)
• Password field fades in (250ms, delay 250ms)
• Button fades in (250ms, delay 350ms)
• All driven by flutter_animate stagger

Behaviour Notes
• Keyboard type: emailAddress for email
• textInputAction: next on email (jumps to password)
• textInputAction: done on password (triggers login)
• Error shown inline below password field - red 12sp
• Button shows spinner during API call


4.2  Counter Home - Cake Gallery

COUNTER HOME - GALLERY
- - -
9:41  ●●●●●  WiFi  🔋
moti BAKERY   [search] [profile]
🔍  Search cakes...
  All   Chocolate   Custom   Fruit   Premium  →

[ 🎂 IMG ]  Black Forest          ₹380/kg
[ 🎂 IMG ]  Strawberry Dream      ₹320/kg
[ 🎂 IMG ]  Truffle Royale        ₹520/kg
[ 🎂 IMG ]  Mango Delight         ₹290/kg

Gallery  |  My Orders
< Home  |  Recents

Layout
Grid columns
2 columns
Column gap
12dp
Row gap
12dp
Grid padding
16dp all sides
Search bar
56dp height, 16dp horizontal margin, 12dp vertical margin
Filter row
Horizontal scroll, 8dp gap, 16dp leading padding
Filter chip
32dp height, 12dp H padding, 8dp border radius
Active chip
Orange bg, white text
Inactive chip
White bg, grey text, 1dp grey border

Shimmer Loading State
• 4 shimmer cards shown (2x2 grid) while API loads
• Shimmer gradient: left to right, #F4F4F4 to #E8E8E8
• Shimmer animation: 1200ms loop

Empty State
• Illustration: cake icon 80dp, grey
• Title: 'No cakes found' 18sp
• Sub: 'Try a different search or filter' 14sp grey
• Centred vertically in remaining space


4.3  Cake Detail Screen

CAKE DETAIL SCREEN
- - -
9:41  ●●●●●  WiFi  🔋
←  Cake Detail
[ HERO IMAGE - full width, 220dp tall ]
Black Forest Cake
Premium chocolate & cherry celebration cake

Select Flavour
[Vanilla] [Chocolate ✓] [Strawberry] [Truffle]

Weight Range   0.5 kg - 4 kg
Base Rate: ₹380/kg

Place Order
< Home  |  Recents

Hero Image
Height
220dp, full width
Fit
Cover - never letterboxed
Hero tag
'cake_image_${id}' - matches gallery card
Top radius
0dp (full bleed)
Bottom
Fades into white with gradient overlay

Flavour Chips
Layout
Horizontal wrap (Wrap widget)
Gap
8dp horizontal, 8dp vertical
Unselected
White bg, 1dp grey border, grey text
Selected
Orange bg, white text, no border
Selection
Single-select - one flavour only
Animation
Color lerp 150ms on select

Bottom CTA
Position
Fixed at bottom, above nav bar
Padding
16dp horizontal, 12dp vertical
Background
White with 1dp top border
Button
Full width primary button



4.4  Place Order Screen

PLACE ORDER SCREEN
- - -
9:41  ●●●●●  WiFi  🔋
←  Place Order
Black Forest - Chocolate Flavour

Weight (kg)
1.5 kg
━━━━━━━●━━━━  Slide to adjust
Delivery Date
📅  12 March 2026
Customer Name (optional)
Name...
Notes (optional)
Special instructions...
📷  Attach Reference Image
Total: ₹ 855.00
Confirm Order
< Home  |  Recents

Weight Input
Input type
Number - decimal allowed
Validation
Real-time - red if below min or above max
Slider
CupertinoSlider, orange thumb, min→max range
Slider sync
Slider and text field stay in sync bidirectionally
Min/Max label
Shown below slider: '0.5 kg' on left, '4 kg' on right

Price Calculator
Position
Fixed card above submit button
Background
#FFF0EB (orange pale)
Border radius
12dp
Price text
26sp Bold, #D94F1E
Breakdown
14sp grey: 'Base ₹570 + Flavour ₹285'
Animation
AnimatedSwitcher on value change - price flips vertically
Padding
16dp all sides

Image Attachment
Trigger
Tapping shows ModalBottomSheet: Camera / Gallery / Cancel
Preview
80x80dp thumbnail with X button to remove
Compression
Max 800px wide, 80% JPEG quality before upload
Upload
On form submit - not on attach

Form Scroll
• Entire form is scrollable (SingleChildScrollView)
• Price card + button are sticky at bottom (not scrollable)
• Keyboard avoidance: form scrolls up when keyboard appears


4.5  Order Confirmation Screen

ORDER CONFIRMATION
- - -
9:41  ●●●●●  WiFi  🔋
Order Confirmed

✓  Order Placed Successfully!
🎂 Lottie animation plays here

Order Summary
Order ID:   #ORD-2026-0042
Cake:        Black Forest (Chocolate)
Weight:      1.5 kg
Delivery:    12 March 2026
Total Paid: ₹ 855.00

Place Another Order
View My Orders
< Home  |  Recents

Lottie Animation Spec
File
order_success.json (Lottie)
Source
LottieFiles - cake/celebration category
Size
200x200dp, centred
Duration
2.5 seconds, plays once
After
Animation stays on last frame (checkmark/cake)
Haptic
HeavyImpact haptic fires at animation start

Order ID Display
Font
Monospace (Courier), 16sp, orange
Copyable
Long press shows 'Copy' tooltip
Format
#ORD-YYYY-XXXX

Navigation
Back disabled
Cannot go back to order form (prevents double order)
'Place Another'
Pops to Gallery, clears order form state
'View Orders'
Navigates to My Orders screen
Back button
App bar back goes to Gallery (not form)

Confetti Effect
• Package: confetti (pub.dev)
• Fires from top-center, 3 second burst
• Colours: #D94F1E, #F28B5B, #FFFFFF
• Plays simultaneously with Lottie


4.6  My Orders Screen

MY ORDERS SCREEN
- - -
9:41  ●●●●●  WiFi  🔋
←  My Orders

#ORD-0042  Black Forest  →  ● Prepared
  1.5 kg • Chocolate • 12 Mar

#ORD-0041  Strawberry Dream  →  ◕ In Progress
  2 kg • Vanilla • 12 Mar

#ORD-0040  Truffle Royale  →  ○ New
  3 kg • Truffle • 14 Mar


Gallery  |  My Orders ●
< Home  |  Recents

Order List Item
Height
80dp per item
Padding
16dp horizontal, 12dp vertical
Order ID
14sp Mono, #D94F1E
Cake name
16sp SemiBold, #1C1C1C
Status badge
Right-aligned, pill badge
Sub-line
12sp, #9E9E9E - weight, flavour, delivery date
Tap area
Full row - navigates to read-only detail
Divider
1dp #E8E8E8 between items
Sort order
Newest first

Real-time Status Update
Polling
30-second interval while screen is active
FCM trigger
Status change pushes update instantly
Badge animate
Old badge fades out (150ms), new badge fades in + scales from 0.8 (200ms)
Prepared alert
In-app banner appears at top: 'Order #42 is ready!'
Banner style
Green bg, white text, 4dp border radius, auto-dismiss 4s

Empty State
• Icon: clipboard 60dp, grey
• 'No orders yet' 18sp
• 'Browse the gallery to place your first order' 14sp grey
• Link: 'Go to Gallery' - orange text button


4.7  Cake Room Dashboard

CAKE ROOM DASHBOARD
- - -
9:41  ●●●●●  WiFi  🔋
Cake Room  ·  3 Active Orders  [logout]
New (2)
In Progress (1)  |  Prepared (3)

#ORD-0040  Truffle Royale  - 3 kg
  Truffle • Delivery: TODAY 3PM  ⚠ URGENT

#ORD-0039  Mango Delight  - 1 kg
  Mango • Delivery: 13 Mar 6PM


← Swipe card to start  →
< Home  |  Recents

Tab Bar
Tabs
3 tabs: New / In Progress / Prepared
Active tab
#FFF0EB bg, #D94F1E text + 3dp bottom indicator
Inactive
White bg, #9E9E9E text
Count badge
Number in parentheses - updates in real-time
Animation
Sliding underline indicator (300ms ease)

Order Card
Height
88dp
Padding
16dp all sides
Order ID
13sp Mono, #D94F1E
Cake + weight
18sp SemiBold, #1C1C1C
Sub-line
13sp grey - flavour + delivery info
Urgent state
Left border 4dp #E65100 (amber), delivery text orange
Overdue state
Left border 4dp #C62828 (red), delivery text red
Tap
Opens Order Detail screen (slide-up transition)
Swipe hint
Subtle right-swipe gesture opens quick actions

Header Summary Bar
• Just below app bar: '3 Active Orders' in 14sp grey
• Updates live as orders are completed

Real-time Refresh
• Polling every 60 seconds when screen is active
• FCM new-order notification triggers immediate refresh
• Pull-to-refresh supported (RefreshIndicator - orange)


4.8  Order Detail - Cake Room

ORDER DETAIL (CAKE ROOM)
- - -
9:41  ●●●●●  WiFi  🔋
←  Order #ORD-0040  [New]
Truffle Royale
Flavour: Truffle  |  Weight: 3 kg
Delivery: TODAY 3:00 PM  ⚠
Customer: Mr. Shah

Notes
Write 'Happy Anniversary' in gold lettering.

Reference Image
[ Reference image - tap to zoom ]

Total: ₹1,560.00

Start Preparation
< Home  |  Recents

Status Action Logic
Current Status
Button Label
Next Status
New
Start Preparation
In Progress
In Progress
Mark as Prepared
Prepared
Prepared
No action - read only
-

Confirmation Bottom Sheet
Trigger
Tapping action button
Style
Glassmorphism - frosted blur background (BackdropFilter)
Sheet height
280dp
Border radius
24dp top corners
Title
18sp Bold - 'Start preparation for #ORD-0040?'
Confirm btn
Full-width primary orange button
Cancel
Text button below - 'Cancel' in grey
Animation
Slides up from bottom (300ms cubic ease)
Blur
BackdropFilter sigma: 10, overlay #1C1C1C at 40%

Reference Image
Display
Full width, max 240dp height, cover fit, 12dp radius
Tap action
Opens full-screen viewer (fade transition)
Pinch zoom
Supported in full-screen viewer
No image
Grey placeholder with camera icon




5. Animation & Motion Specification

5.1  Animation Inventory
Animation
Package
Trigger
Duration
Curve
Login screen entry stagger
flutter_animate
Screen mount
300ms per item, 150ms stagger
easeOut
Gallery card entry stagger
flutter_animate
Gallery load
250ms per card, 60ms stagger
easeOut
Gallery card press feedback
flutter_animate
onTapDown
100ms scale to 0.97
easeInOut
Hero: card → detail image
Flutter Hero
Card tap
Managed by Flutter
Default spring
Flavour chip color change
AnimatedContainer
Chip tap
150ms
easeInOut
Price counter update
AnimatedSwitcher
Weight/flavour change
200ms
easeInOut + flip
Order success Lottie
lottie
Order placed
2500ms, plays once
N/A
Confetti burst
confetti
Order placed
3000ms
N/A
Status badge change
AnimatedSwitcher
Status update
200ms
fade + scale
Screen transition: gallery flow
animations (Google)
Navigation
300ms
Shared axis horizontal
Screen transition: tabs
animations (Google)
Tab switch
250ms
Fade-through
Bottom sheet slide up
Flutter showModal
Button tap
300ms
cubic (0.2,0,0,1)
Prepared in-app banner
flutter_animate
FCM received
300ms slide down, 4s auto-dismiss
easeOut
Tab indicator slide
AnimatedContainer
Tab switch
300ms
easeInOut
Bottom nav icon pulse
flutter_animate
Tab select
200ms scale 1→1.2→1
spring
App bar shadow on scroll
AnimatedContainer
ScrollController
200ms
linear
Shimmer loading
shimmer
Screen load
1200ms loop
linear

5.2  Lottie File Guidelines
• All Lottie files must be in /assets/animations/ directory
• Use LottieFiles.com - search: 'cake', 'celebration', 'checkmark', 'confetti'
• File size limit: 150kb per file - avoid heavy Lottie files on mobile
• Prefer vector-only Lottie (no rasterized images embedded)
• Test on a mid-range Android device - Lottie can drop frames on low-end hardware
• Always set repeat: false for success animations

5.3  Performance Rules
Animation Performance Guidelines
Never run more than 2 Lottie animations simultaneously.
Use RepaintBoundary around animated widgets to isolate paint layers.
Avoid animating widgets that have expensive builds (large lists).
Use const constructors wherever possible to prevent unnecessary rebuilds.
The price counter AnimatedSwitcher must use a key based on value, not rebuild the entire form.
Shimmer loading: dispose shimmer controller when data loads to free GPU resources.




6. Accessibility & UX Standards

6.1  Touch Target Rules
Element
Minimum Tap Target
Minimum Visual Size
Primary button
52dp height (full width)
52dp
Icon buttons
48x48dp
24dp icon
Gallery card
Full card tap
Variable
Filter chip
40dp height
32dp
Status badge
Not tappable
Varies
Text links
40dp height padded
14sp text
Bottom nav item
56dp height, full width
24dp icon

6.2  Text Legibility
• Minimum body text: 14sp - never go below this for readable content
• Minimum contrast ratio: 4.5:1 for normal text (WCAG AA)
• Orange (#D94F1E) on white: 4.7:1 ratio - passes WCAG AA
• White on orange: always passes - high contrast
• Never use midGray (#9E9E9E) text on non-white backgrounds

6.3  Error Handling UX
Error Type
How Displayed
Recovery Action
Form validation
Inline red text below field, field border turns red
User corrects field
Login failure
Red message below button: 'Invalid email or password'
User re-enters
Network error
SnackBar at bottom: 'Check your connection' with Retry
Tap Retry
API error (order)
SnackBar: 'Could not place order. Try again.' - persists
Tap Retry
Image upload fail
Toast: 'Image upload failed - order saved without image'
Order proceeds
Session expired
Dialog: 'Session ended - please log in again'
Navigate to Login
No internet on launch
Full screen: offline illustration + 'Reconnect' button
Tap Reconnect

6.4  Loading State Rules
• Gallery initial load: shimmer skeleton cards - never a spinner in the grid
• Button loading: spinner inside button - button stays same size, never shifts layout
• Status update: button shows spinner, entire card shows 50% opacity while updating
• Image loading in gallery: CachedNetworkImage with SSIM fade-in (300ms)
• Full-screen loads (initial app): orange circular indicator centred on white screen



7. Flutter Theme Implementation

Below is the complete ThemeData configuration to implement this design system in Flutter.

7.1  theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MotibakeryTheme {
  // Brand Colors
  static const Color primary       = Color(0xFFD94F1E);
  static const Color primaryLight   = Color(0xFFF28B5B);
  static const Color primaryPale    = Color(0xFFFFF0EB);
  static const Color textPrimary    = Color(0xFF1C1C1C);
  static const Color textSecondary  = Color(0xFF4A4A4A);
  static const Color textHint       = Color(0xFF9E9E9E);
  static const Color borderLight    = Color(0xFFE8E8E8);
  static const Color surfaceGray    = Color(0xFFF4F4F4);
  static const Color statusGreen    = Color(0xFF2E7D32);
  static const Color statusBlue     = Color(0xFF1565C0);
  static const Color error          = Color(0xFFC62828);
  static const Color warning        = Color(0xFFE65100);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      background: Colors.white,
      surface: const Color(0xFFFAFAFA),
      error: error,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1C1C1C),
      elevation: 0,
      shadowColor: Color(0x1A000000),
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
      floatingLabelStyle: const TextStyle(color: primary),
    ),
    chipTheme: ChipThemeData(
      selectedColor: primary,
      labelStyle: const TextStyle(fontSize: 13),
      shape: const StadiumBorder(),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primary,
      unselectedItemColor: Color(0xFF9E9E9E),
      elevation: 8,
    ),
  );
}



8. Assets, Fonts & Resource Checklist

8.1  Font
Font
Weights Needed
Source
Flutter Package
Inter
300, 400, 500, 600, 700
Google Fonts
google_fonts: ^6.x.x

8.2  Icons
Icon Set
Usage
Source
Material Symbols (Rounded)
All UI icons - app bar, nav bar, form icons
Built-in Flutter + material_symbols_icons package
Custom SVG logo
Motibakery logo in app bar and login screen
Design team - provide as SVG, import as flutter_svg

8.3  Lottie Animation Files Required
File Name
Used On
Description
Max Size
order_success.json
Order Confirmation
Cake + celebration / confetti burst
100kb
loading_cake.json
Splash screen
Simple cake icon spinning / building
60kb

• Source: LottieFiles.com - Free to use commercial files only
• Alternatively: hire a motion designer to create custom Motibakery-branded Lottie
• Test all Lottie files on Android API 28 (Android 9) for compatibility

8.4  pubspec.yaml Assets Section
flutter:
  assets:
    - assets/images/logo.svg
    - assets/images/empty_orders.svg
    - assets/images/empty_gallery.svg
    - assets/images/offline.svg
    - assets/animations/order_success.json
    - assets/animations/loading_cake.json
  fonts:
    # Loaded via google_fonts package - no local font files needed



9. Designer → Developer Handoff Checklist

Use this checklist before starting development to ensure all design assets and decisions are locked.

Item
Status
Owner
Brand color hex values confirmed
Required before dev start
Brand / Client
Logo SVG provided (transparent bg)
Required before dev start
Brand / Client
Inter font licensed / google_fonts confirmed
Ready - google_fonts free
Dev
Lottie order_success.json sourced
Source from LottieFiles
Dev / Designer
Lottie loading_cake.json sourced
Source from LottieFiles
Dev / Designer
Empty state illustrations (SVG)
Required before UI polish
Designer
Offline illustration (SVG)
Required before UI polish
Designer
All screen measurements documented
Done - this document
This Doc
Animation durations confirmed
Done - Section 5
This Doc
Component states documented
Done - Section 3
This Doc
Figma or design mockup created
Recommended before build
Designer
Android splash screen asset
Required for release
Designer
App icon (adaptive icon for Android)
Required for release
Designer

Motibakery UI/UX Design Specification  |  Phase 1 MVP  |  Confidential
Motibakery - Flutter UI/UX Design Specification   |   Bold Modern Theme   |   Phase 1 MVP

Confidential - Motibakery & ASYNK

