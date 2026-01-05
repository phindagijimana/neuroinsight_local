/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Override blue colors with custom #003d7a theme
        blue: {
          50: '#f8fafc',   // Very light neutral
          100: '#f1f5f9',  // Light neutral
          200: '#0066cc',  // Bright #003d7a variant for animations
          300: '#003d7a',  // Exact #003d7a color for animations
          400: '#94a3b8',  // Medium neutral
          500: '#64748b',  // Medium gray
          600: '#003d7a',  // Primary color ✨
          700: '#003d7a',  // Same as 600 for consistency
          800: '#002850',  // Darker variant for emphasis
          900: '#001a33',  // Darkest for strong contrast
        },
      },
    },
  },
  plugins: [],
}



