<?php
$_SERVER['REQUEST_URI'] = '/api/health';
$_SERVER['REQUEST_METHOD'] = 'GET';
require __DIR__ . '/../vendor/autoload.php';
AgriPass\Core\Auth::start();
$router = new AgriPass\Core\Router();
$routes = require __DIR__ . '/../src/routes.php';
$routes($router);
$router->dispatch(AgriPass\Core\Request::capture());
