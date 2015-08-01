inflect = require 'inflect'
manager = require './manager'
controller = require './controller'

class Bald
  constructor: ({app, sequelize}) ->
    throw new Error 'Arguments invalid.' if !app? || !sequelize?
    @app = app
    @sequelize = sequelize

  resource: ({model, endpoints, middleware, eagerLoading}) ->
    throw new Error 'Invalid model.' if !model?

    endpoints = endpoints || {}
    if !endpoints.plural? && !endpoints.singular?
      plural = inflect.pluralize model.name

      endpoints = {
        plural: '/api/' + plural
        singular: '/api/' + plural + '/:id'
      }

    modelManager = manager model, eagerLoading
    controller @app, endpoints, modelManager, middleware

    return modelManager

module.exports = Bald
