// Generated by CoffeeScript 1.12.0
(function() {
  var ApiTools, BaldError, _, async, processValue, sendResponse;

  async = require('async');

  _ = require('underscore');

  ApiTools = require('./ApiTools');

  BaldError = require('./Error');

  sendResponse = ApiTools.sendResponse;

  processValue = function(value) {
    if (value === '$bald$null') {
      return null;
    }
    return value;
  };

  module.exports = function(arg) {
    var app, endpoints, knex, middleware, model, primaryKey, routes;
    app = arg.app, knex = arg.knex, endpoints = arg.endpoints, model = arg.model, primaryKey = arg.primaryKey, middleware = arg.middleware;
    routes = [
      {
        name: 'list',
        method: 'get',
        url: endpoints.plural,
        handler: function(req, res) {
          return knex(model).select().then(function(data) {
            return sendResponse(res, null, data);
          })["catch"](function(err) {
            return sendResponse(res, err);
          });
        }
      }, {
        name: 'read',
        method: 'get',
        url: endpoints.singular,
        handler: function(req, res) {
          var where;
          where = {};
          where[primaryKey] = req.params.pk;
          return knex(model).select().where(where).then(function(arg1) {
            var data;
            data = arg1[0];
            return sendResponse(res, null, data);
          })["catch"](function(err) {
            return sendResponse(res, err);
          });
        }
      }, {
        name: 'create',
        method: 'post',
        url: endpoints.plural,
        handler: function(req, res) {
          var values;
          values = _.mapObject(req.body, processValue);
          return async.waterfall([
            function(done) {
              return knex(model).insert(values).then(function(arg1) {
                var id;
                id = arg1[0];
                return done(null, id);
              })["catch"](done);
            }, function(id, done) {
              var where;
              where = {};
              where[primaryKey] = id;
              return knex(model).select().where(where).then(function(arg1) {
                var data;
                data = arg1[0];
                return done(null, data);
              })["catch"](done);
            }
          ], function(err, data) {
            return sendResponse(res, err, data);
          });
        }
      }, {
        name: 'update',
        method: 'put',
        url: endpoints.singular,
        handler: function(req, res) {
          var values, where;
          values = _.mapObject(req.body, processValue);
          values[primaryKey] = req.params.pk;
          where = {};
          where[primaryKey] = req.params.pk;
          return async.waterfall([
            function(done) {
              return knex(model).where(where).update(values).then(function(data) {
                return done();
              })["catch"](done);
            }, function(done) {
              return knex(model).where(where).select().then(function(arg1) {
                var data;
                data = arg1[0];
                return done(null, data);
              })["catch"](done);
            }
          ], function(err, data) {
            return sendResponse(res, err, data);
          });
        }
      }, {
        name: 'delete',
        method: 'delete',
        url: endpoints.singular,
        handler: function(req, res) {
          var where;
          where = {};
          where[primaryKey] = req.params.pk;
          return knex(model).where(where).del().then(function(data) {
            return sendResponse(res, null, data);
          })["catch"](function(err) {
            return sendResponse(res, err);
          });
        }
      }
    ];
    return routes.map(function(route) {
      var routeMiddleware;
      if ((middleware != null) && typeof middleware !== 'object') {
        throw new BaldError('BaldControllerError', 'Invalid middleware array provided.');
      }
      if (middleware != null) {
        routeMiddleware = middleware[route.name] || [];
      }
      if (middleware == null) {
        routeMiddleware = [];
      }
      return app[route.method](route.url, routeMiddleware, route.handler);
    });
  };

}).call(this);
