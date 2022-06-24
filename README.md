# danger-shroud

A danger plugin for enforcing code coverage coverage via a Kover or Jacoco coverage report.

![Shroud Banner Image](images/bannerImage.png)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'danger-shroud'
```

## Usage Kover

Shroud depends on having a Kover coverage report generated for your project. For Android projects, [kotlinx-kover](https://github.com/Kotlin/kotlinx-kover) works well. 

Running shroud with default values:

```ruby
# Report coverage of modified files, fail if either total 
# project coverage or any modified file's coverage is under 90%
shroud.reportKover 'Module Name', 'path/to/kover/report.xml'
```

Running shroud with custom coverage thresholds:

```ruby
# Report coverage of modified files, fail if total project coverage is under 80%,
# or if any modified file's coverage is under 95%
shroud.reportKover 'Module Name', 'path/to/kover/report.xml', 80, 95
```

Warn on builds instead of fail:

```ruby
# Report coverage of modified files the same as the above example, except the
# builds will only warn instead of fail if below thresholds
shroud.reportKover 'Module Name', 'path/to/kover/report.xml', 80, 95, false
```


## Usage Jacoco

Shroud depends on having a Jacoco coverage report generated for your project. For Android projects, [jacoco-android-gradle-plugin](https://github.com/arturdm/jacoco-android-gradle-plugin) works well. 

Running shroud with default values:

```ruby
# Report coverage of modified files, fail if either total 
# project coverage or any modified file's coverage is under 90%
shroud.reportJacoco 'Module Name', 'path/to/jacoco/report.xml'
```

Running shroud with custom coverage thresholds:

```ruby
# Report coverage of modified files, fail if total project coverage is under 80%,
# or if any modified file's coverage is under 95%
shroud.reportJacoco 'Module Name', 'path/to/jacoco/report.xml', 80, 95
```

Warn on builds instead of fail:

```ruby
# Report coverage of modified files the same as the above example, except the
# builds will only warn instead of fail if below thresholds
shroud.reportJacoco 'Module Name', 'path/to/jacoco/report.xml', 80, 95, false
```




## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.