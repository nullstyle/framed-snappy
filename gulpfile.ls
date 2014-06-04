require! gulp
plugins = require('gulp-load-plugins')!

paths =
  build: ['./src/**/*.ls']
  watch: ['./gulpfile.js', './lib/**', './test/**/*.js', '!test/{temp,temp/**}']
  tests: ['./test/**/*.ls', '!test/{temp,temp/**}']

gulp.task 'build', ->
  gulp
    .src paths.build
    .pipe plugins.livescript bare: true
    .pipe gulp.dest('./lib')

gulp.task 'mocha', ['build'] ->
  gulp
    .src  paths.tests, cwd: __dirname
    .pipe plugins.spawn-mocha(reporter: 'list', compilers:"ls:livescript")


gulp.task 'bump', ['test'], ->
  bump-type = process.env.BUMP || 'patch'

  gulp
    .src  ['./package.json']
    .pipe plugins.bump(type: bump-type)
    .pipe gulp.dest('./')


gulp.task 'watch', ->
  gulp.run 'test'
  gulp.watch paths.watch, ['test']

gulp.task 'default', ['test']
gulp.task 'test',    ['mocha']
gulp.task 'release', ['bump']
