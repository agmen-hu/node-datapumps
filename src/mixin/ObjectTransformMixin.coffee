#
# Includes common transformations for objects like making property names lowercase.
#
objectTransformMixin = ->
  (target) ->
    # Converts property names to lower case.
    target.propertiesToLowerCase = (data) ->
      result = {}
      for prop,value of data
        result[prop.toLowerCase()] = value
      result

    # Throws exception when property or array of properties are missing from object.
    target.requireProperty = (obj, properties) ->
      properties = if Array.isArray properties then properties else [ properties ]
      for property in properties
        throw new Error 'Missing property: ' + property if !obj[property]?

      if properties.length == 1
        obj[properties[0]]
      else
        result = {}
        result[property] = obj[property] for property in properties
        result

    # Returns boolean true for any value other than "off", "false", "no", false, null or undefined
    target.boolValueOf = (obj) ->
      !(obj == null || obj == undefined || obj == false || obj == 'off' ||
        obj == 'false' || obj == 0 || obj == 'no')

module.exports = objectTransformMixin
