#!/usr/bin/env node

var yaml = require('yamljs');
var env = process.argv.length > 2 ? process.argv[2] : 'local';
var settings_path = process.argv.length > 3 ? process.argv[3] : 'settings.yml';

var resolved_settings = yaml.load(settings_path)[env];
console.log(JSON.stringify(resolved_settings));
