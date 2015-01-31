randomInRange = function(min, max) {
  var random = Math.floor(Math.random() * (max - min + 1)) + min;
  return random;
}

randomFromCollection = function(C) {
  return function () {
    c = C.find().fetch();
    i = randomInRange(0, C.find().count())
    return c[i]
  }
}