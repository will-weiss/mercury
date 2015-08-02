process.env.TZ = 'UTC';
require('coffee-script/register');

// The global Promise object comes from bluebird
// https://github.com/petkaantonov/bluebird
global.Promise = require('bluebird').Promise;

try {
  require('./lib/boot')();
} catch(err) {
  console.log(err.stack);
}
