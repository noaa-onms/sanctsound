The following button is for rendering the website:

[![Github Action - render_website](https://img.shields.io/badge/SanctSound-render--website-green)](https://github.com/noaa-onms/sanctsound/actions/workflows/render-website.yml)

- Then "Run workflow", assuming you are logged into Github with an account granted Collaborator status on this repository.
- You might do this after making changes to [sanctsound website content - Google Sheets](https://docs.google.com/spreadsheets/d/1zmbqDv9KjWLYD9fasDHtPXpRh5ScJibsCHn56DYhTd0/edit#gid=206020376). 
- Note that this Github Action gets run after every new commit.

## Create Website

- [R Markdown Websites](https://rmarkdown.rstudio.com/lesson-13.html)
- [10.5 rmarkdown’s site generator | R Markdown: The Definitive Guide](https://bookdown.org/yihui/rmarkdown/rmarkdown-site.html)
- [R Markdown Websites](https://garrettgman.github.io/rmarkdown/rmarkdown_websites.html#publishing_websites)


# Infographic rendering

This website uses a simple interactive infographics implementation based on JavaScript only (ie not using the R-based [infographiq](https://github.com/marinebon/infographiq)).

## technical implementation

The illustration in scalable vector graphics (`.svg`) format has individual elements given an identefier (ie `id`) which are linked to popup (ie "modal") windows of content using a simple table in comma-seperated value (`.csv`) format using [d3](https://d3js.org).

### core files: `.svg`, `.csv`

These two files are at the core of the infographic construction:

1. **illustration**: [`cinms_pelagic.svg`](https://github.com/marinebon/cinms/blob/master/svg/cinms_pelagic.svg) 
1. **table**: [`svg_links.csv`](https://github.com/marinebon/iea-ak-info/blob/master/svg/svg_links.csv) 

Each `link` in the table per element identified (`id`) is the page of content displayed in the modal popup window when the given element is clicked. The `title` determines the name on hover and title of the modal window.

### html and js/css dependencies

The illustration (`.svg`) and table (`.csv`) get rendered with the `link_svg()` function (defined in `infographiq.js`) with the following HTML:

```html
<!-- load dependencies on JS & CSS -->
<script src='https://d3js.org/d3.v5.min.js'></script>
<script src='infographiq.js'></script>

<!-- add placeholder in page for placement of svg -->
<div id='svg'></div>

<!-- run function to link the svg -->
<script>link_svg(svg='svg/cinms_pelagic.svg', csv='svg/svg_links.csv');</script>
```

The modal popup windows are rendered by [Bootstrap modals](https://getbootstrap.com/docs/3.3/javascript/#modals). This dependency is included with the default Rmarkdown rendering, but if you need to seperately include it then add this HTML:

```html
<!-- load dependencies on JS & CSS -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css">
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
```

## build and view website in R

This website is constructed using [Rmarkdown website](https://bookdown.org/yihui/rmarkdown/rmarkdown-site.html) for enabling easy construction of site-wide navigation (see [`_site.yml`](https://github.com/marinebon/iea-ak-info/blob/master/_site.yml)) and embedding of [htmlwidgets](https://www.htmlwidgets.org), which provide interactive maps, time series plots, etc into the html pages to populate the modal window content in [`modals/`](https://github.com/marinebon/iea-ak-info/tree/master/modals). To build the website and view it, here are the commands to run in R:

## develop

### content editing workflow

1. edit .Rmd files in `./docs/modals/`
2. run `script render_site.R`

NOTE: The `.html` files *can* be edited but by default `.html` files are overwritten by content knit from the `Rmd` files of the same name.
To use html directly set `redo_modals <- T`, but you will need to clear `.html` files manually with this setting.

### testing

Because of [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) restrictions, need local web server to debug:

```r
# build website
source("render_site.R")

# serve website
#servr::httd(".")
servr::httd(here::here(""))

# stop website
servr::daemon_stop(1)
```

or using Python:

```bash
cd ~/github/cinms/docs; python -m SimpleHTTPServer
```

The [`render_site.R`](https://github.com/marinebon/iea-ak-info/blob/master/render_site.R) script renders the modal and website pages.

Note the actual html content served at [marinebon.github.io/cinms](https://marinebon.github.io/cinms) via [Github Pages](https://pages.github.com/) is all the html/jss/csss files copied into the `docs/` folder of this repository.
