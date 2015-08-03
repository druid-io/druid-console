'use strict';

var gulp = require('gulp');
var sass = require('gulp-sass');
var concat = require('gulp-concat');
var source = require('vinyl-source-stream');
var browserify = require('browserify');

var config = {
  bowerDir: './bower_components'
}

gulp.task('static', function() {
  gulp.src(config.bowerDir + '/font-awesome/fonts/**.*')
      .pipe(gulp.dest('./build/fonts'));

  gulp.src([config.bowerDir + '/bootstrap/dist/css/bootstrap-theme.css',
            config.bowerDir + '/bootstrap/dist/css/bootstrap.css',
            config.bowerDir + '/font-awesome/css/font-awesome.css'])
      .pipe(gulp.dest('./build/css'));

  gulp.src('./static/console.html')
      .pipe(concat('index.html'))
      .pipe(gulp.dest('./build/'));

  gulp.src(['./static/favicon.ico'])
      .pipe(gulp.dest('./build/'));

  gulp.src(['./static/pages/**/*'])
      .pipe(gulp.dest('./build/pages'));
});

gulp.task('sass', function () {
  return gulp.src('./src/client/**/*.scss')
      .pipe(sass({ outputStyle: 'expanded' }).on('error', sass.logError))
      .pipe(concat('druid.css'))
      .pipe(gulp.dest('./build/'));
});

gulp.task('browserify', function() {
     return browserify({
        entries: ['./src/client/druid.coffee'],
        extensions: ['.coffee']
     })
    .transform('coffeeify')
    .bundle()
    .pipe(source('druid.js'))
    .pipe(gulp.dest('./build/'));
});

gulp.task('watch', function() {
    gulp.watch('./src/client/**/*.coffee', [ 'browserify']);
    gulp.watch('./src/**/*.scss', ['sass']);
});

gulp.task('default', ['static', 'sass', 'browserify']);
