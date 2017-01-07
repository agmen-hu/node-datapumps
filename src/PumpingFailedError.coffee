module.exports = class PumpingFailedError extends Error
  name: 'PumpingFailedError'

  constructor: (@message = 'Pumping failed. See .errorBuffer() contents for error messages') ->
    super @message
