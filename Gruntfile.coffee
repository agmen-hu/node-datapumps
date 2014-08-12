module.exports = ->
  @initConfig
    pkg: @file.readJSON 'package.json'

    coffee:
      base:
        expand: true
        cwd: 'src'
        src: ['*.coffee']
        dest: 'lib'
        ext: '.js'
      mixins:
        expand: true
        cwd: 'src/mixin'
        src: ['*.coffee']
        dest: 'lib/mixin'
        ext: '.js'

    # Automated recompilation and testing during development
    watch:
      files: ['src/*.coffee', 'src/**/*.coffee' ]
      tasks: ['test']

    cafemocha:
      specs:
        src: ['src/spec/*.coffee', 'src/mixin/spec/*.coffee']
        options:
          require: 'coffee-script/register'
          reporter: 'dot'

  # Grunt plugins used for building
  @loadNpmTasks 'grunt-contrib-coffee'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-contrib-watch'
  @loadNpmTasks 'grunt-cafe-mocha'

  # Our local tasks
  @registerTask 'build', 'Build datapumps', =>
    @task.run 'coffee'

  @registerTask 'test', 'Build datapumps and run tests', =>
    @task.run 'coffee'
    @task.run 'cafemocha'

  @registerTask 'default', ['test']
