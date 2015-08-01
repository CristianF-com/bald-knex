async = require 'async'
_ = require 'underscore'

{makeOperation} = require('./common')
Association = require('./association')

handleError = (err, next) ->
  # NOTE: We need `(err, null)` here, so that we have an argument length of 2.
  # This is because this argument array will be used later, and so we need
  # to know that the second argument would represent the values.
  return next(err, null) if err.name == 'SequelizeValidationError'
  return throw err

module.exports = (model, eagerLoading) ->
  create = makeOperation (values, done) ->
    query = query || {}
    query.include = {all: true, nested: true} if eagerLoading?

    async.waterfall [
      (done) ->
        model.create(values)
          .then (data) -> Association.attempt model, data, values, done
          .catch (err) -> handleError err, done
      (data, done) ->
        query.where = data.get()
        model.find(query).then (data) -> done(null, data)
    ], (err, data) ->
      done(err, data)

  list = makeOperation (options, done) ->
    query = query || {}
    query.include = {all: true, nested: true} if eagerLoading?

    if options.filter? && options.filterBy?
      query.where = {}
      query.where[options.filterBy] = options.filter

    if options.limit? && options.offset?
      query.limit = +options.limit
      query.offset = +options.offset

    if options.sort? && options.sortBy?
      query.order = options.sortBy + ' ' + options.sort

    model.findAll query
      .then (data) -> done null, data
      .catch (err) -> handleError err, done

  read = makeOperation (whereQuery, done) ->
    query = where: whereQuery
    query.include = all: true, nested: true if eagerLoading?

    model.find query
      .then (data) -> done null, data
      .catch (err) -> handleError err, done

  update = makeOperation (id, values, done) ->
    query = where: id: id
    query.include = all: true, nested: true if eagerLoading?

    async.waterfall [
      (done) ->
        model.update(values, query)
          .then (data) -> done null
          .catch (err) -> handleError err, done
      (done) ->
        model.find query
          .then (data) -> Association.attempt model, data, values, done
          .catch (err) -> handleError err, done
    ], (err, data) ->
      done err, data

  updateMultiple = makeOperation (values, done) ->
    updateValue = (value, done) ->
      async.waterfall [
        (done) ->
          model.update value, where: id: value.id
            .then (data) -> done null
            .catch (err) -> handleError err, done
        (done) ->
          query = where: id: value.id
          query.include = all: true, nested: true if eagerLoading?

          model.find query
            .then (data) -> done null, value
            .catch (err) -> handleError err, done
      ], (err, data) ->
        done null, data
    async.map values, updateValue, done

  del = makeOperation (id, done) ->
    model.destroy where: id: id
      .then (data) -> done null, data
      .catch (err) -> handleError err, done

  return {
    create
    list
    read
    update
    updateMultiple
    del
  }
