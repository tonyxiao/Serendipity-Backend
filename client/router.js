Router.route('/', function () {
  // render the Home template with a custom data context
  this.render('Home');
});

Router.route('/photos');