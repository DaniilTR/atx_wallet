/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        ffffff: "var(--ffffff)",
        "highcharts-core-vikafjell-colors-general-axistitles":
          "var(--highcharts-core-vikafjell-colors-general-axistitles)",
        "highcharts-core-vikafjell-colors-general-labels":
          "var(--highcharts-core-vikafjell-colors-general-labels)",
      },
    },
  },
  plugins: [],
};
