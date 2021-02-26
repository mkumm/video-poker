module.exports = {
  purge: [
    '../lib/**/*.ex',
    '../lib/**/*.leex',
    '../lib/**/*.eex',
    './js/**/*.js'
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
      container: {
        center: true,
        padding: '2rem',
      },
    extend: {},
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
