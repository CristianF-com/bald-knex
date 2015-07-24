async = require 'async'
{makeOperation} = require('./common')()

module.exports = (model, eagerLoading) ->
  create = makeOperation (values, done) ->
    model.create values
      .then (data) -> done null, data

  list = makeOperation (done) ->
    query = {}
    query.include = {all: true, nested: true} if eagerLoading?

    model.findAll query
      .then (data) -> done null, data

  read = makeOperation (whereQuery, done) ->
    query = where: whereQuery
    query.include = all: true, nested: true if eagerLoading?

    model.find query
      .then (data) -> done null, data

  update = makeOperation (id, values, done) ->
    query = where: id: id
    query.include = all: true, nested: true if eagerLoading?

    async.waterfall [
      (done) ->
        model.update values, query
          .then (data) -> done null
      (done) ->
        model.find query
          .then (data) -> done null, data
    ], (err, data) ->
      done err, data

  updateMultiple = makeOperation (values, done) ->
    updateValue = (value, done) ->
      async.waterfall [
        (done) ->
          model.update value, where: id: value.id
            .then (data) -> done null
        (done) ->
          query = where: id: value.id
          query.include = all: true, nested: true if eagerLoading?

          model.find query
            .then (data) -> done null, value
      ], (err, data) ->
        done null, data
    async.map values, updateValue, done

  del = makeOperation (id, done) ->
    model.destroy where: id: id
      .then (data) -> done null, data

  return {
    create
    list
    read
    update
    updateMultiple
    del
  }
