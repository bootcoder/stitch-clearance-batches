# Installation

## Ruby

We recommend using RVM or RBENV to manage your Ruby environment. System-provided Ruby versions are often several 
versions behind what will work for new Rails applications. Upgrading your system Ruby is not recommended, as it is 
often very challenging and could break system components.

### Install RVM (recommended)

Always check for the latest installation instructions at https://rvm.io/

If using a Mac, you may be prompted to install Xcode Developer Tools if you haven't already. Please do so, as it 
provides the necessary make tools to compile Ruby and gems with native system extensions.

### Install a Ruby version

After RVM is installed and you have reloaded your Terminal windows to allow the `rvm` command to work, check the 
file .ruby-version in the unzipped project directory to determine which Ruby version you need to install 
and run `rvm install ruby-[version]`. You could also simply `cd` into the project directory in your Terminal window 
and RVM should tell you which version it is expecting and how to install it, like so:

```
$ cd [unzipped project folder location]
ruby-2.4.2 is not installed.
To install do: 'rvm install ruby-2.4.2'
```

If using a Mac, you may be prompted to install Homebrew in order to install necessary dependencies if you don't have 
it installed already.

## Install Bundler and project Ruby Gems

Bundler helps to manage Ruby Gems, which are packages of Ruby code and are defined by the Gemfile. This is how Ruby on Rails 
and related open source code used to create the application are installed.

Install it by first running:

```
gem install bundler
```

You should then be able to set everything up in one step:

```
bin/setup
```

## Running the Application

Run the following from the project directory:

```
bin/rails server
```

You should then be able to view the application using your web browser at http://localhost:3000/  (If that doesn't work, check 
the output of the `bin/rails server` command to see if a different port other than 3000 was indicated.)

## Running Tests

Run the following from the project directory:

```
bin/rspec
```
