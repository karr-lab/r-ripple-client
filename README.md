# rippler

## Communicate with Ripple Science from R

_Note: this package is in early stages and in progress!_ 

### To Do

* [ ] Implement config files for auth details and custom variables (currently custom vars are hardcoded in `zzz.R` and auth details are manually added as env vars. 

* [ ] Proper Readme

* [ ] Support exporting xlsx files, importing csv files 

* [ ] Allow passing options to final `httr:req_perform` command

* [ ] Allow filtering exports on date


### Authentication 

Add the following to your ~/.Renviron file, or provide them whenever calling the functions. If not set here,
Rippler will ask for your Ripple username and password in a dialog box. 

```
RIPPLER_RIPPLE_URL=https://myripplesite.ripplescience.com
RIPPLER_STUDY_ID=abcdefghijk123
RIPPLER_RIPPLE_USER=myemail@mycompany.com
RIPPLER_RIPPLE_PASS=yourPassword123
```

### Ripple API Details

https://support.ripplescience.com/hc/en-us/categories/21426318229389-Application-Programming-Interface-API

### Gripes

* It would be really nice if the exported file were in the same format as what's needed for importing. E.g. why no importType/ field? Why does sex export in lower case but needs title case for import?

* A complete API documentation would be nice
