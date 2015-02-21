Router.route('/', function () {
  // render the Home template with a custom data context
  this.render('home');
});

Router.route('/photos');

Router.route('/add');

Router.route('/matched');

Router.route('/users');