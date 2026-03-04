import tailwindcssAnimate from 'tailwindcss-animate';

/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ['class'],
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: '#D94F1E',
          light: '#F28B5B',
          pale: '#FFF0EB',
          dark: '#B83E12',
        },
        sidebar: {
          bg: '#1A1A2E',
          text: '#A8A8C0',
          border: '#2A2A45',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'Courier New', 'monospace'],
      },
      boxShadow: {
        card: '0 2px 8px rgba(0,0,0,0.06)',
        modal: '0 8px 32px rgba(0,0,0,0.12)',
        brand: '0 4px 16px rgba(217,79,30,0.20)',
      },
    },
  },
  plugins: [tailwindcssAnimate],
};
