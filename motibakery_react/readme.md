
MOTIBAKERY
Admin CMS Web Panel
React Frontend - Technical Documentation

Stack
Vite + React 18 + Tailwind CSS v3
Role
Admin - Full CMS Control
Auth
JWT - Role-based access
Phase
Phase 1 - MVP
Version
v1.0
Companion Docs
Flutter App Spec + Backend API (separate)


1. Project Overview

The Motibakery Admin CMS is a web-based dashboard that gives the business owner and admin team full control over the entire ordering ecosystem. It is the backbone of the Flutter app - everything the counter staff and cake room sees is managed from here.

What the Admin CMS Controls
Products - add, edit, delete cakes, configure flavours, weight limits, images, categories
Pricing Rules - create flavour-based price increments, enable/disable rules anytime
Users - create Counter and Cake Room accounts, edit roles, deactivate, reset passwords
Orders - view all orders, filter by date/status, export to Excel
Excel Import/Export - bulk manage products and pricing via downloadable templates


1.1  CMS vs Flutter App Responsibilities
Concern
Admin CMS (React)
Flutter App
Create user accounts
Yes - full control
No - no self-signup
Manage cake products
Yes - full CRUD + images
Read only
Set pricing rules
Yes - create/edit/toggle
Reads + applies rules
Place orders
View only
Yes - Counter role
Update order status
View only
Yes - Cake Room role
Bulk Excel import
Yes
No
View analytics
Phase 2
No
Push notifications
No
Yes - FCM



2. Technology Stack

The CMS is a Single Page Application (SPA) built with Vite + React 18 + Tailwind CSS. It communicates with the same backend API that serves the Flutter app.

2.1  Core Stack
Layer
Technology
Version
Purpose
Build Tool
Vite
^5.x
Fast dev server, optimised production build
UI Framework
React
^18.x
Component-based UI, concurrent features
Styling
Tailwind CSS
^3.x
Utility-first styling - consistent, fast
Routing
React Router DOM
^6.x
Client-side routing with protected routes
State (global)
Zustand
^4.x
Lightweight global state - auth, UI state
Server State
TanStack Query (React Query)
^5.x
API data fetching, caching, mutations
Forms
React Hook Form
^7.x
Performant forms with validation
Validation
Zod
^3.x
Schema-based form + API validation
HTTP Client
Axios
^1.x
API calls with interceptors, token refresh
UI Components
shadcn/ui
latest
Headless, accessible component primitives
Icons
Lucide React
^0.4xx
Consistent icon set, tree-shakeable
Tables
TanStack Table
^8.x
Powerful headless table with sorting/filter
Charts (Phase 2)
Recharts
^2.x
Analytics charts - orders, revenue trends
Excel
SheetJS (xlsx)
^0.18
Client-side Excel import/export
Toast / Notify
Sonner
^1.x
Clean toast notifications
Date Picker
React Day Picker
^8.x
Accessible, Tailwind-compatible date picker
Image Upload
react-dropzone
^14.x
Drag-and-drop image upload with preview

2.2  Project Scaffold
npm create vite@latest motibakery-cms -- --template react
cd motibakery-cms
npm install

# Tailwind CSS
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Core packages
npm install react-router-dom zustand @tanstack/react-query axios
npm install react-hook-form @hookform/resolvers zod
npm install @tanstack/react-table lucide-react sonner
npm install react-dropzone react-day-picker date-fns xlsx

# shadcn/ui setup
npx shadcn-ui@latest init

2.3  Folder Structure
src/
  ├── main.jsx                   # App entry - QueryClient + Router + Providers
  ├── App.jsx                    # Route definitions
  ├── assets/                    # Static assets (logo, icons)
  ├── components/
  │   ├── ui/                    # shadcn/ui base components (Button, Input, etc.)
  │   ├── layout/
  │   │   ├── Sidebar.jsx        # Navigation sidebar
  │   │   ├── Topbar.jsx         # Top header bar
  │   │   └── AdminLayout.jsx    # Wrapper: Sidebar + Topbar + main content
  │   ├── shared/
  │   │   ├── DataTable.jsx      # Reusable TanStack Table wrapper
  │   │   ├── PageHeader.jsx     # Page title + breadcrumb + action button
  │   │   ├── StatusBadge.jsx    # Reusable status pill
  │   │   ├── ConfirmDialog.jsx  # Delete / action confirmation modal
  │   │   ├── ImageUpload.jsx    # Drag-and-drop image uploader
  │   │   └── ExcelImport.jsx    # Excel upload + preview component
  │   └── forms/
  │       ├── CakeForm.jsx       # Add / Edit cake form
  │       ├── UserForm.jsx       # Add / Edit user form
  │       └── PricingForm.jsx    # Add / Edit pricing rule form
  ├── pages/
  │   ├── auth/
  │   │   └── LoginPage.jsx
  │   ├── dashboard/
  │   │   └── DashboardPage.jsx
  │   ├── products/
  │   │   ├── ProductsPage.jsx   # List + filters
  │   │   └── ProductDetailPage.jsx
  │   ├── pricing/
  │   │   └── PricingPage.jsx
  │   ├── users/
  │   │   └── UsersPage.jsx
  │   └── orders/
  │       ├── OrdersPage.jsx     # List + filters
  │       └── OrderDetailPage.jsx
  ├── hooks/
  │   ├── useAuth.js             # Auth state from Zustand
  │   ├── useCakes.js            # TanStack Query hooks for cakes API
  │   ├── useOrders.js           # TanStack Query hooks for orders API
  │   ├── useUsers.js            # TanStack Query hooks for users API
  │   └── usePricing.js          # TanStack Query hooks for pricing rules
  ├── stores/
  │   └── authStore.js           # Zustand - token, user, role
  ├── lib/
  │   ├── axios.js               # Axios instance + interceptors
  │   ├── queryClient.js         # TanStack QueryClient config
  │   └── utils.js               # cn(), formatDate(), formatPrice()
  └── config/
      └── routes.js              # Route path constants



3. Routing & Authentication

3.1  Route Map
Path
Component
Protected
Notes
/login
LoginPage
No
Redirect to /dashboard if already authed
/
redirect
Yes
Redirect to /dashboard
/dashboard
DashboardPage
Yes
Summary stats + recent activity
/products
ProductsPage
Yes
Cake list with search, filter, bulk actions
/products/new
ProductDetailPage
Yes
Add new cake form
/products/:id/edit
ProductDetailPage
Yes
Edit cake form - prefilled
/pricing
PricingPage
Yes
Pricing rules list + add/edit/toggle
/users
UsersPage
Yes
User list + create/edit/deactivate
/orders
OrdersPage
Yes
Order list with filters + export
/orders/:id
OrderDetailPage
Yes
Read-only order detail view
*
NotFoundPage
No
404 page

3.2  Protected Route Implementation
// src/components/layout/ProtectedRoute.jsx
import { Navigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';

export function ProtectedRoute({ children }) {
  const { token, user } = useAuthStore();
  if (!token) return <Navigate to='/login' replace />;
  if (user?.role !== 'admin') return <Navigate to='/login' replace />;
  return children;
}

3.3  Auth Store (Zustand)
// src/stores/authStore.js
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export const useAuthStore = create(
  persist(
    (set) => ({
      token: null,
      user:  null,
      setAuth: (token, user) => set({ token, user }),
      clearAuth: () => set({ token: null, user: null }),
    }),
    { name: 'motibakery-auth' }  // persists to localStorage
  )
);

3.4  Axios Instance + Token Interceptor
// src/lib/axios.js
import axios from 'axios';
import { useAuthStore } from '@/stores/authStore';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  timeout: 10000,
});

api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      useAuthStore.getState().clearAuth();
      window.location.href = '/login';
    }
    return Promise.reject(err);
  }
);

export default api;



4. Layout System

4.1  Admin Layout
All protected pages share the AdminLayout component - a fixed sidebar on the left and a fixed top bar, with the main content scrolling in the right panel.

ADMIN LAYOUT - All Pages

moti BAKERY - Admin CMS          [Search...]          [Bell] [Admin User ▼]

  NAVIGATION
  Dashboard
  Products  ← Active
  Pricing Rules
  Users
  Orders

  MAIN CONTENT AREA - changes per page
  Page content renders here (scrollable)
  Sidebar is fixed - stays in place on scroll
Browser window - Admin CMS

4.2  Layout Measurements
Sidebar width
240px - fixed, not collapsible in Phase 1
Sidebar background
#1A1A2E (near-black navy) - distinct from page background
Top bar height
56px - fixed
Main content
calc(100vw - 240px), starts at 56px top offset
Page padding
32px all sides inside main content area
Max content width
1280px centered for wide monitors
Sidebar logo
moti in orange, BAKERY in white, 20px bold - top of sidebar
Nav item height
44px, 16px horizontal padding
Active nav item
White text, orange left border 3px, slightly lighter bg
Sidebar footer
Logged-in user name + role + logout button at bottom



5. Page-by-Page Specification

5.1  Login Page
The only public page. Full-screen centered layout - no sidebar.

LOGIN PAGE

  (White background - full screen centered)
  [Motibakery Logo]
  Welcome back
  Sign in to your admin account

  Email Address
  admin@motibakery.com
  Password
  ••••••••••••

  Sign In
  Admin access only - contact owner for access
Browser window - Admin CMS

Layout
Card width
420px, centered
Card shadow
0 4px 24px rgba(0,0,0,0.08)
Card radius
16px
Logo
80px x 80px, above heading
Heading
Inter 28px Bold
Sub text
14px, #9E9E9E

Form Behaviour
• Email: type=email, autoComplete=email
• Password: type=password, show/hide toggle icon
• Submit: Enter key on password field triggers submit
• Error: red text below button - 'Invalid credentials'
• Loading: button shows spinner + disabled
• On success: store token in Zustand + redirect to /dashboard


5.2  Dashboard Page
Landing page after login. Shows key metrics at a glance and recent order activity.

DASHBOARD PAGE

moti BAKERY - Admin CMS                                    Admin User ▼
  Dashboard   -   Good morning, Admin!

  Total Orders Today: 12       Active Cakes: 34       Users: 5       Pending Orders: 3

  Recent Orders
  #ORD-0042   Black Forest   Counter A   12 Mar 3PM   [Prepared]
  #ORD-0041   Truffle Royale Counter A   12 Mar 5PM   [In Progress]
  #ORD-0040   Mango Delight  Counter B   14 Mar 6PM   [New]

  Quick Actions
  + Add New Cake    |    + Add User    |    View All Orders
Browser window - Admin CMS

Dashboard Stat Cards
Stat Card
Data Source
Click Action
Total Orders Today
GET /orders?date=today count
Navigates to /orders filtered to today
Active Cakes
GET /cakes?status=active count
Navigates to /products
Total Users
GET /users count
Navigates to /users
Pending Orders
GET /orders?status=new count
Navigates to /orders?status=new



5.3  Products Page - Cake Management
Core page for managing the cake catalogue. Admins can add, edit, toggle active/inactive, delete, and bulk import via Excel.

PRODUCTS PAGE

moti BAKERY Admin                                         Admin User ▼
  Products   /   Cake Catalogue

  [Search: 'black forest...']  [Category ▼]  [Status ▼]   [Import Excel]  [+ Add Cake]

  ID    |  Name                |  Category  |  Rate    |  Weight      |  Flavours  |  Status  |  Actions
  #C001 |  Black Forest        |  Chocolate |  ₹380/kg |  0.5 - 4 kg  |  3         |  Active  |  Edit  Delete
  #C002 |  Strawberry Dream    |  Fruit     |  ₹320/kg |  1 - 3 kg    |  2         |  Active  |  Edit  Delete
  #C003 |  Truffle Royale      |  Premium   |  ₹520/kg |  1 - 5 kg    |  4         |  Active  |  Edit  Delete
  #C004 |  Classic Vanilla     |  Standard  |  ₹280/kg |  0.5 - 3 kg  |  1         |  Inactive|  Edit  Delete

  Showing 1-10 of 34 cakes      [← Prev]  Page 1 of 4  [Next →]
Browser window - Admin CMS

Products Table Columns
Column
Sortable
Filterable
Notes
Image
No
No
40x40px thumbnail, rounded
ID
Yes
No
Mono font, copy on click
Name
Yes
Yes
Search field filters this
Category
Yes
Yes
Dropdown filter
Base Rate
Yes
No
₹ per kg
Min-Max Weight
No
No
Range display
Flavours
No
No
Count badge, hover to see list
Status
Yes
Yes
Active/Inactive toggle switch
Actions
No
No
Edit icon + Delete icon

Products Page - Key Interactions
Interaction
Behaviour
+ Add Cake button
Opens right-side drawer (Drawer/Sheet component) with CakeForm
Edit icon
Opens same drawer prefilled with cake data
Delete icon
Opens ConfirmDialog - 'Delete Black Forest? This cannot be undone.'
Active toggle switch
PATCH /cakes/:id/status - instant optimistic update with rollback on error
Import Excel button
Opens ExcelImport modal - drag-drop or browse, preview table, confirm import
Row click
Expands inline row to show full details (flavours list, notes, full image)
Search input
Client-side filter on name, 300ms debounce
Category dropdown
Sends filter param to API - server-side filter
Status dropdown
Sends filter param to API - server-side filter
Pagination
TanStack Table pagination - 10 rows per page default


5.4  Add / Edit Cake - Form Drawer
Opens as a slide-in drawer from the right side - does not navigate away from the products list. Uses React Hook Form + Zod validation.

ADD / EDIT CAKE DRAWER

  Add New Cake  ×

  Cake Name *
  Black Forest Cake
  Category / Tags
  [Chocolate ×]  [Premium ×]  + Add tag
  Base Rate (₹ per kg) *
  380
  Min Weight (kg) *   Max Weight (kg) *
  0.5                    4.0
  Flavours (comma separated) *
  Vanilla, Chocolate, Strawberry, Truffle
  Description / Notes
  Premium chocolate sponge with...
  Cake Image - Drag & drop or Browse
  [Image Preview 120x120]  Click to change
  Status
  Active  ●  (Toggle switch)

  Save Cake
  Cancel
Browser window - Admin CMS

Form Fields & Validation
Field
Required
Validation Rule
Cake Name
Yes
Min 2 chars, max 80 chars
Category
No
Multi-tag input, min 0
Base Rate
Yes
Number > 0, max 99999
Min Weight
Yes
Number > 0, < maxWeight
Max Weight
Yes
Number > minWeight
Flavours
Yes
At least 1 flavour required
Description
No
Max 500 chars
Image
No
JPG/PNG/WEBP, max 5MB
Status
Yes
Boolean toggle, defaults to Active

Submit Behaviour
• On Add: POST /cakes - success shows toast + closes drawer + refreshes list
• On Edit: PUT /cakes/:id - success shows toast + closes drawer + updates row
• Errors: inline Zod messages below each field
• Duplicate name: API 409 error shown below name field
• Image upload: fires separately on file select (POST /upload/image), URL stored in form state
• Drawer closes on overlay click with unsaved-changes confirmation dialog


5.5  Pricing Rules Page
Allows the admin to configure price adjustments that the Flutter app applies automatically during order placement.

PRICING RULES PAGE

moti BAKERY Admin                                        Admin User ▼
  Pricing Rules   -   Configure price adjustments

  [+ Add Rule]   [Import Excel]   [Export Excel]

  Rule Name        |  Type        |  Applies To    |  Increment  |  Status  |  Actions
  Chocolate Premium|  Flavour     |  Chocolate     |  +₹50/kg    |  Active  |  Edit  Delete
  Truffle Luxury   |  Flavour     |  Truffle       |  +12%       |  Active  |  Edit  Delete
  Premium Category |  Category    |  Premium tag   |  +₹100/kg   |  Inactive|  Edit  Delete
  Weekend Surcharge|  Global      |  All cakes     |  +5%        |  Inactive|  Edit  Delete

  4 rules total - 2 active
Browser window - Admin CMS

Pricing Rules - Form Fields
Field
Type
Required
Notes
Rule Name
Text input
Yes
Descriptive label for admin reference
Rule Type
Select dropdown
Yes
Flavour / Category / Global
Applies To
Conditional input
Yes
Flavour name OR category tag (hidden if Global)
Increment Type
Radio toggle
Yes
Flat (₹/kg) OR Percentage (%)
Increment Amount
Number input
Yes
Positive number - e.g. 50 or 12
Status
Toggle switch
Yes
Active/Inactive - can change anytime

Pricing Rule Logic - How it Works
Flavour rule: applies if customer selects that specific flavour
Category rule: applies if the cake belongs to that category tag
Global rule: applies to all orders regardless of flavour or category
Multiple rules can match - all matching rules are added together
Formula: Total = (BaseRate + FlatIncrements + PercentIncrements) x Weight
Admin can enable/disable any rule instantly - Flutter app fetches rules on login



5.6  Users Page
Admin creates and manages all user accounts. No user can sign up themselves - all accounts flow through here.

USERS PAGE

moti BAKERY Admin                                        Admin User ▼
  Users   -   Manage access

  [Search users...]   [Role ▼]   [Status ▼]   [+ Add User]

  Name            |  Email                    |  Role         |  Status  |  Last Login  |  Actions
  Priya Shah       |  counter1@motibakery.com  |  Counter      |  Active  |  Today 9AM   |  Edit  Deactivate
  Rajan Mehta      |  cakeroom@motibakery.com  |  Cake Room    |  Active  |  Today 9AM   |  Edit  Deactivate
  Aarti Patel      |  counter2@motibakery.com  |  Counter      |  Active  |  Yesterday   |  Edit  Deactivate
  Old Staff        |  old@motibakery.com       |  Counter      | Inactive |  3 weeks ago |  Edit  Activate

  4 users - 3 active, 1 inactive
Browser window - Admin CMS

User Form Fields
Field
Required
Validation
Notes
Full Name
Yes
Min 2, max 60 chars
Display name in app header
Email
Yes
Valid email, must be unique
Used as login username
Role
Yes
counter or cake_room
Select dropdown - determines app dashboard
Password
Yes (Add only)
Min 8 chars
Only shown on Add. Edit shows Reset button
Status
Yes
active or inactive
Inactive users cannot log in to Flutter app

User Actions
• Edit: opens drawer with form prefilled - password field replaced by 'Reset Password' button
• Reset Password: opens small dialog - admin enters new password manually, confirms
• Deactivate: PATCH /users/:id/status - user cannot log in, their session is revoked by backend
• Activate: re-enables a deactivated account
• Delete: permanently removes user - only if user has zero associated orders


5.7  Orders Page
Read-only view of all orders placed through the Flutter Counter app. Admin can filter, search, and export to Excel.

ORDERS PAGE

moti BAKERY Admin                                        Admin User ▼
  Orders   -   All orders

  [Search by ID / name]  [Date: From-To]  [Status ▼]  [Export Excel]

  Order ID   |  Cake            |  Weight  |  Delivery       |  Total    |  Status      |  Created
  #ORD-0042  |  Black Forest    |  1.5 kg  |  12 Mar 3:00PM  |  ₹855     |  [Prepared]  |  Today 9:12AM
  #ORD-0041  |  Truffle Royale  |  3 kg    |  12 Mar 5:00PM  |  ₹1,560   |  [In Progress]| Today 8:50AM
  #ORD-0040  |  Mango Delight   |  1 kg    |  14 Mar 6:00PM  |  ₹290     |  [New]       |  Yesterday 4PM

  Showing 1-10 of 156 orders         [← Prev]  Page 1 of 16  [Next →]
Browser window - Admin CMS

Orders Table - Columns & Filters
Column / Filter
Type
Behaviour
Order ID
Column
Mono font, click to open detail page
Cake Name
Column + Search
Text search across cake name and customer name
Flavour
Column
Shown as small text
Weight
Column
kg display
Delivery Date
Column + Filter
Date range picker - filter from/to
Total Price
Column
₹ formatted
Status Badge
Column + Filter
Dropdown: All / New / In Progress / Prepared
Created At
Column + Sort
Default sort - newest first
Actions
Column
Eye icon - view detail (read only)
Export Excel
Button
Exports current filtered view to .xlsx

5.8  Order Detail Page
Full read-only view of a single order. Admin cannot modify orders - order status is only changeable by the Cake Room via the Flutter app.

URL
/orders/:id
Access
Admin - read only
Layout
Two-column: left side order info, right side reference image + timeline
Order info shown
Order ID, cake name, flavour, weight, delivery date + time, customer name, notes, total price
Reference image
Displayed full size if present, placeholder if not
Status timeline
Visual timeline: New → In Progress → Prepared with timestamps
Back button
Returns to Orders list preserving filters and scroll position
Export
Single order export to PDF - Phase 2



6. Excel Import / Export

A key admin feature - allows bulk product and pricing management without navigating individual forms. Uses SheetJS for client-side parsing and generation.

6.1  Products Excel Import Flow
Step
Action
Technical Detail
1
Admin clicks 'Import Excel' on Products page
Opens ImportModal component
2
Admin downloads base template
GET /excel/templates/products - returns .xlsx with correct headers
3
Admin fills template offline
Edits in Microsoft Excel or Google Sheets
4
Admin uploads filled file
react-dropzone - .xlsx / .xls accepted, max 5MB
5
Client parses the file
SheetJS reads workbook, converts to JSON array
6
Preview table shown
First 20 rows shown in a preview table inside modal
7
Validation runs client-side
Zod validates each row - flags errors inline in preview
8
Admin reviews + confirms
Sees 'X rows valid, Y rows with errors'
9
POST /products/import
Sends JSON array to backend - backend processes + responds with summary
10
Import summary displayed
Modal shows: Added, Updated, Skipped, Errors - with downloadable error file

6.2  Excel Template - Products
Column Header
Required
Format
Notes
id
No
Text
Leave blank for new cakes, fill for updates
name
Yes
Text
Max 80 chars
base_rate
Yes
Number
₹ per kg - e.g. 380
min_weight
Yes
Number
kg - e.g. 0.5
max_weight
Yes
Number
kg - e.g. 4.0
flavours
Yes
Text
Comma-separated - e.g. Vanilla,Chocolate
categories
No
Text
Comma-separated tag names
status
Yes
active/inactive
Case insensitive
notes
No
Text
Max 500 chars

6.3  Import Validation Rules
• name is empty → row skipped with reason: 'Name is required'
• base_rate is not a positive number → row flagged as error
• min_weight >= max_weight → row flagged as error
• status is not 'active' or 'inactive' → row flagged as error
• Duplicate name (existing cake) + no id provided → row treated as update by name match
• id provided but does not exist in DB → row flagged as error
• Images: cannot be managed via Excel - only via CMS upload

6.4  Orders Excel Export
• Triggered by 'Export Excel' button on Orders page
• Exports current filtered view - respects all active filters (date range, status)
• SheetJS generates .xlsx client-side - no server roundtrip needed
• Filename: motibakery_orders_YYYY-MM-DD.xlsx
Columns exported
Order ID, Cake Name, Flavour, Weight, Customer Name, Delivery Date, Total Price, Status, Created At
Row limit
Up to 5000 rows per export
Format
Dates in DD/MM/YYYY, prices in ₹ format



7. Shared Component Library

All reusable components built once and used across every page. Built on top of shadcn/ui primitives with Motibakery brand customisation.

7.1  DataTable Component
Library
TanStack Table v8 - headless
Sorting
Click column header - asc/desc/none cycle
Pagination
Client-side for small sets, server-side for orders (cursor-based)
Row selection
Checkbox column - enables bulk delete on Products page
Empty state
Custom EmptyState component per page context
Loading state
Skeleton rows (3 shimmer rows) while data fetches
Column resize
Not required in Phase 1
Export
External - Export button triggers SheetJS, not part of table
Sticky header
Yes - thead stays visible on scroll
Row hover
bg-orange-50 on hover, cursor-pointer

7.2  PageHeader Component
// Usage
<PageHeader
  title='Products'
  breadcrumb={['Admin', 'Products']}
  action={{ label: '+ Add Cake', onClick: openDrawer }}
  secondaryAction={{ label: 'Import Excel', onClick: openImport }}
/>

Title
24px SemiBold, dark
Breadcrumb
12px grey, separator '/'
Action button
Primary orange button - right-aligned
Secondary action
Outline button - right of primary
Bottom border
1px #E8E8E8 separator below header

7.3  StatusBadge Component
// Usage
<StatusBadge status='prepared' />
<StatusBadge status='in_progress' />
<StatusBadge status='new' />
<StatusBadge status='active' />
<StatusBadge status='inactive' />

Status Value
Label
Tailwind Classes
new
New
bg-gray-100 text-gray-600 - pill, 12px SemiBold
in_progress
In Progress
bg-blue-50 text-blue-700 - pill, 12px SemiBold
prepared
Prepared
bg-green-50 text-green-700 - pill, 12px SemiBold
active
Active
bg-orange-50 text-orange-600 - pill, 12px SemiBold
inactive
Inactive
bg-gray-100 text-gray-400 - pill, 12px SemiBold

7.4  ConfirmDialog Component
// Usage
<ConfirmDialog
  open={isOpen}
  title='Delete Black Forest Cake?'
  description='This will permanently remove the cake and all associated data.'
  confirmLabel='Delete'
  confirmVariant='destructive'
  onConfirm={handleDelete}
  onCancel={() => setIsOpen(false)}
/>

Style
shadcn/ui AlertDialog - centered modal, backdrop blur
Confirm button
Red background for destructive, orange for normal actions
Cancel button
Outline, grey
Title
18px Bold
Description
14px grey, explains the consequence
Loading state
Confirm button shows spinner + disabled during API call

7.5  ImageUpload Component
Library
react-dropzone
Accepts
image/jpeg, image/png, image/webp
Max size
5MB - shows error if exceeded
Drop zone
Dashed border, 160px height, centered icon + text
Hover state
Orange dashed border, orange icon
Preview
120x120 thumbnail with remove (X) button on top-right
Upload timing
Uploads immediately on file select - returns URL stored in form
Progress
Linear progress bar during upload
Error state
Red text below dropzone: 'Upload failed - try again'



8. Tailwind Configuration

The Tailwind config extends the default theme with Motibakery brand tokens. All brand colors are accessible as Tailwind utility classes throughout the project.

8.1  tailwind.config.js
/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ['class'],
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT:  '#D94F1E',
          light:    '#F28B5B',
          pale:     '#FFF0EB',
          dark:     '#B83E12',
        },
        sidebar: {
          bg:       '#1A1A2E',
          text:     '#A8A8C0',
          border:   '#2A2A45',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'Courier New', 'monospace'],
      },
      borderRadius: {
        DEFAULT: '8px',
        lg: '12px',
        xl: '16px',
        '2xl': '24px',
      },
      boxShadow: {
        card:   '0 2px 8px rgba(0,0,0,0.06)',
        modal:  '0 8px 32px rgba(0,0,0,0.12)',
        brand:  '0 4px 16px rgba(217,79,30,0.20)',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
};

8.2  CSS Variables (globals.css)
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --brand:          217 59% 47%;
    --brand-light:    21 85% 64%;
    --background:     0 0% 100%;
    --foreground:     0 0% 11%;
    --muted:          0 0% 96%;
    --muted-foreground: 0 0% 45%;
    --border:         0 0% 91%;
    --radius:         0.5rem;
  }
}



9. TanStack Query - API Hooks

All server state is managed by TanStack Query. Each domain has its own hooks file that wraps API calls with useQuery and useMutation.

9.1  Cakes Hooks - useCakes.js
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/axios';

// Fetch all cakes (with optional filters)
export const useCakes = (filters = {}) =>
  useQuery({
    queryKey: ['cakes', filters],
    queryFn: () => api.get('/cakes', { params: filters }).then(r => r.data),
  });

// Create cake
export const useCreateCake = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data) => api.post('/cakes', data).then(r => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['cakes'] });
      toast.success('Cake added successfully');
    },
  });
};

// Update cake
export const useUpdateCake = () => { ... }  // PUT /cakes/:id

// Toggle active status (optimistic)
export const useToggleCakeStatus = () => { ... }  // PATCH /cakes/:id/status

// Delete cake
export const useDeleteCake = () => { ... }  // DELETE /cakes/:id

9.2  Query Key Conventions
Resource
List Key
Detail Key
Mutation Invalidates
Cakes
['cakes', filters]
['cakes', id]
['cakes']
Orders
['orders', filters]
['orders', id]
['orders']
Users
['users', filters]
['users', id]
['users']
Pricing
['pricing-rules']
['pricing-rules', id]
['pricing-rules']

9.3  QueryClient Configuration
// src/lib/queryClient.js
import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime:        1000 * 60 * 5,   // 5 minutes
      gcTime:           1000 * 60 * 10,  // 10 minutes (formerly cacheTime)
      retry:            2,
      refetchOnWindowFocus: false,
    },
    mutations: {
      onError: (error) => {
        toast.error(error.response?.data?.message || 'Something went wrong');
      },
    },
  },
});



10. CMS Design System

The CMS uses the same brand orange as the Flutter app but has its own visual language - structured, data-dense, professional. The sidebar is dark navy to anchor the layout and visually separate navigation from content.

10.1  Color System
Token
Hex
Tailwind Class
Usage
Brand Orange
#D94F1E
brand / bg-brand
Primary buttons, active states, focus rings, links
Brand Light
#F28B5B
brand-light
Hover states on brand elements
Brand Pale
#FFF0EB
brand-pale
Row hover, active nav bg, tag backgrounds
Sidebar BG
#1A1A2E
sidebar-bg
Fixed left sidebar background
Sidebar Text
#A8A8C0
sidebar-text
Inactive nav item labels
Page BG
#FFFFFF
bg-white
Main content area background
Surface
#FAFAFA
bg-gray-50
Table row alternates, card backgrounds
Border
#E8E8E8
border-gray-200
All dividers, card borders, table lines
Text Primary
#1C1C1C
text-gray-900
Headings, table data, form labels
Text Secondary
#4A4A4A
text-gray-600
Descriptions, subtitles
Text Muted
#9E9E9E
text-gray-400
Timestamps, placeholders, helper text

10.2  Typography
Style
Size
Weight
Usage
Page Title
24px
SemiBold 600
Main page heading in PageHeader
Section Heading
18px
SemiBold 600
Card titles, drawer headings, section labels
Table Header
13px
Medium 500
Column headers - uppercase, letter-spaced
Table Body
14px
Regular 400
All table cell content
Form Label
14px
Medium 500
Input field labels
Form Input
15px
Regular 400
Input field content
Stat Value
28px
Bold 700
Dashboard metric numbers
Stat Label
13px
Regular 400
Dashboard metric labels
Badge
12px
SemiBold 600
Status pill labels
Button
14px
SemiBold 600
All button labels
Breadcrumb
12px
Regular 400
Navigation breadcrumb
Monospace
13px
Regular 400
Order IDs, product IDs

10.3  Spacing & Grid
• Base unit: 4px (Tailwind default). All spacing is multiples of 4.
• Page padding: p-8 (32px) inside main content area
• Card padding: p-6 (24px)
• Table cell padding: py-3 px-4 (12px, 16px)
• Form field gap: space-y-4 (16px) between fields
• Section gap: space-y-8 (32px) between page sections
• Sidebar nav gap: space-y-1 (4px) between nav items



11. Environment & Deployment

11.1  Environment Variables
# .env.development
VITE_API_URL=http://localhost:3000/api
VITE_APP_NAME=Motibakery Admin

# .env.production
VITE_API_URL=https://api.motibakery.com/api
VITE_APP_NAME=Motibakery Admin

11.2  Build & Preview
npm run dev        # Start Vite dev server - http://localhost:5173
npm run build      # Production build - outputs to /dist
npm run preview    # Preview production build locally

11.3  Deployment Options
Platform
Steps
Notes
Vercel (recommended)
Connect GitHub repo - auto-deploys on push to main
Set VITE_API_URL in Vercel env settings
Netlify
Connect GitHub - auto-deploys, add _redirects for SPA routing
Add: /* /index.html 200 in public/_redirects
Firebase Hosting
firebase init hosting → firebase deploy
Set rewrites in firebase.json for SPA routing
VPS / Nginx
Build → copy /dist to server → Nginx serves static files
Configure Nginx try_files for client-side routing

11.4  SPA Routing Note
Important: Client-Side Routing
React Router handles routing client-side - the server must redirect all routes to index.html.
Without this, refreshing /products will return a 404 from the server.
Every deployment platform has a specific way to configure this - see table above.




12. Development Checklist

12.1  Setup Tasks
Task
Command / Action
Done
Scaffold Vite + React project
npm create vite@latest motibakery-cms -- --template react

Install Tailwind CSS
npm install -D tailwindcss postcss autoprefixer + init

Install all dependencies
npm install (full list in Section 2.2)

Configure tailwind.config.js
Add brand colors + fonts (Section 8.1)

Add globals.css variables
CSS variables (Section 8.2)

Setup shadcn/ui
npx shadcn-ui@latest init

Configure Axios instance
src/lib/axios.js with interceptors (Section 3.4)

Configure QueryClient
src/lib/queryClient.js (Section 9.3)

Setup React Router
App.jsx with all routes + ProtectedRoute (Section 3)

Create AdminLayout
Sidebar + Topbar wrapper (Section 4)

Set .env files
VITE_API_URL for dev and prod (Section 11.1)


12.2  Feature Build Order (Recommended)
#
Feature
Depends On
1
Login Page + Auth Store
Axios, Zustand, backend /auth/login
2
AdminLayout - Sidebar + Topbar
React Router, auth store
3
Dashboard Page - stats + recent
Layout, orders + products APIs
4
Products Page - table + filters
TanStack Table, cakes API
5
Add / Edit Cake Drawer + Form
React Hook Form, Zod, image upload API
6
Active/Inactive toggle
Products page, PATCH API
7
Excel Import (Products)
SheetJS, import API, ImportModal component
8
Pricing Rules Page
TanStack Table, pricing API
9
Users Page - list + create/edit
TanStack Table, users API
10
Orders Page - table + filters
TanStack Table, orders API, date picker
11
Order Detail Page
Orders page, single order API
12
Orders Excel Export
SheetJS - client-side only
13
Polish - toasts, loading, empty states
Sonner, all pages complete

Motibakery Admin CMS - React Frontend Documentation  |  Phase 1 MVP  |  Confidential
Motibakery - Admin CMS React Frontend Documentation   |   Vite + React + Tailwind   |   Phase 1 MVP

Confidential - Motibakery & ASYNK

