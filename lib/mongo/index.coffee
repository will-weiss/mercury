MongoConnections = require('./connections')

module.exports = new MongoConnections(['titan', 'local', 'logging', 'reports'])
