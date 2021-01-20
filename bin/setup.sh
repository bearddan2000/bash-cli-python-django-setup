#!/usr/bin/env bash
PROJECT="prj_hello_world"
APPS="app_hello app_goodby"
SPLASH="app_home"
DOMAIN="http://localhost:8000"

function _get-short-name {
  # get the first parameter
  # get substr after first _
  # transform any remaining _ to <SPACE>
  # captilize first letter
  echo $1 | cut -d "_" -f 2- | tr '_' ' ' | awk '{for (i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1'
}

function _set-application {

  local application=$1
  local content=$2

  local index_page="${application}.html"

  # create application folder
  python3 manage.py startapp $application

  # create default view
  cat <<VIEW > $application/views.py
from django.shortcuts import render

def ${application}(request):
    return render(request, '${index_page}', {})
VIEW

  cat <<URLS > $application/urls.py
from django.urls import path
from ${application} import views

urlpatterns = [
  path('', views.${application}, name='${application}'),
]
URLS

  # create html for view
  mkdir -p $application/templates
  touch $application/templates/$index_page

  # extend $PROJECT/templates/base.html
  cat <<INDEX > $application/templates/$index_page
  {% extends "base.html" %}

  {% block page_content %}
  ${content}
  {% endblock %}
INDEX

  # reg applications
  sed -i "/    'django.contrib.staticfiles',/a '${application}'," $PROJECT/settings.py

}

function set-env {
  # setup virtual env
  # sudo apt-get install -y python3-venv
  python3 -m venv venv

  # activate project
  source venv/bin/activate
}

function install-django {
  # install Django
  pip install Django
}

function create-project {
  # Create project
  django-admin startproject $PROJECT

  # reconfig project [optional]
  mv $PROJECT/manage.py . \
    && mv $PROJECT/$PROJECT/* $PROJECT \
    && rm -R $PROJECT/$PROJECT

  # create html that will be extend
  mkdir -p $PROJECT/templates
  touch $PROJECT/templates/base.html

  local short_name=$(_get-short-name $PROJECT)

  cat <<BASE > $PROJECT/templates/base.html
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <title>${short_name}</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">
  </head>
  <body>
    <nav class="navbar navbar-default">
      <div class="container-fluid">
        <div class="navbar-header">
          <a class="navbar-brand" href="#">${short_name}</a>
        </div>
        <ul class="nav navbar-nav">
          <li><a href="${DOMAIN}">Home</a></li>
          <!-- Add apps -->
        </ul>
      </div>
    </nav>
    <div class="container">
      {% block page_content %}
      {% endblock %}
    </div>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>
  </body>
  </html>
BASE

  # Add function include
  sed -i "s/from django.urls import path/from django.urls import path, include/" $PROJECT/urls.py

  # let all calls to $PROJECT/templates/base.html
  # point to $PROJECT/templates/
  sed -i "s/'DIRS': \[\],/'DIRS': \['${PROJECT}\/templates\/'\],/" $PROJECT/settings.py
}
function add-splash {
  local app=$SPLASH

  _set-application $app ""

    # add routing
    sed -i "/path('admin\/', admin.site.urls),/a path('', include('${app}.urls'))," $PROJECT/urls.py
}

function add-app {

  # add apps to project
  for x in $APPS; do

  _set-application $x "<h1>This is the index page for ${x} </h1>"

    # add routing
    sed -i "/path('admin\/', admin.site.urls),/a path('${x}\/', include('${x}.urls'))," $PROJECT/urls.py

    # add menu link
    local short_name=$(_get-short-name $x)
    sed -i "/<!-- Add apps -->/a <li><a href=\"\/${x}\/\">${short_name}<\/a><\/li>" $PROJECT/templates/base.html
  done
}

function start-server {

  python3 manage.py migrate

  # run server
  # default localhost:8000
  python3 manage.py runserver
}

set-env
install-django
create-project
add-app
add-splash
# start-server
