
## 2026-02-18 

Come up with a plan to implement the following menu update to to this [rmarkdown site](https://yihui.org/rmarkdown/rmarkdown-site) here @.:

> We would like to request that these same updates be made to the SanctSound <https://sanctsound.ioos.us/> site as well. Andy Nguy, the developer from TetraTech who implemented the changes, has provided instructions<https://gist.github.com/nguyandy/3ad9bacba55996410f3cfecc597f64ee> to assist your web team with this process. Feel free to browse other sites that have already implemented these changes, such as Environmental Sensor Map<https://sensors.ioos.us/>, IOOS HF Radar<https://hfradar.ioos.us/>, MBON Data Portal<https://mbon.ioos.us/>, and others.

Investigate whether the JavaScript might conflict with the use of @libs/infographiq.js and if so, propose fixes.

⏺ The plan is ready. Here's a summary:

  Key finding: No breaking conflicts between the IOOS Web Components and infographiq.js. The Web Components use Shadow DOM, so their CSS/HTML is fully isolated.
  Tooltips use document-relative coordinates (unaffected by layout changes), and Bootstrap modals have higher z-index (1050) than the IOOS header (999).

  4 files to modify, 0 new files:
  1. libs/header.html -- swap old IOOS emblem for the CDN script tag
  2. libs/footer.html -- replace custom footer HTML with <ioos-footer>, add <ioos-header> with jQuery placement, update the scroll handler
  3. libs/styles.css -- remove ~130 lines of dead CSS for old header/footer, update navbar/main-container positioning
  4. libs/infographiq.js -- no changes needed (confirmed safe)

  The only real integration concern is the scroll handler in footer.html that references the old <header> element -- it needs rewriting to work with the new
  <ioos-header> Web Component.

 Ready to code?

 Here is Claude's plan:

 Plan: Integrate IOOS UI Web Components into SanctSound Site

 Context

 The IOOS program has standardized its navigation and footer across partner sites using Web Components (<ioos-header> and <ioos-footer>), loaded from a single
 CDN script. Sites like hfradar.ioos.us and mbon.ioos.us already use them. SanctSound currently has a custom IOOS header (emblem only) and custom footer HTML.
 The task is to replace these with the standardized Web Components while preserving all existing functionality, especially libs/infographiq.js (SVG
 interactivity, modals, tooltips).

 Conflict Analysis: IOOS Web Components vs infographiq.js

 No breaking conflicts found. Reasons:

 1. Shadow DOM isolation -- <ioos-header> and <ioos-footer> use Shadow DOM (attachShadow({mode:"open"})), so their internal CSS/HTML is fully isolated from the
 site's Bootstrap 4 and D3 styles.
 2. Tooltip positioning -- infographiq.js uses d3.event.pageX/pageY (document-relative coordinates). Adding a taller header doesn't affect this.
 3. Modal z-index -- Bootstrap modals default to z-index 1050. The IOOS header's internal navbar uses z-index 999. Modals will display correctly on top.
 4. jQuery / D3 -- Both libraries operate on the light DOM and are unaffected by Shadow DOM components.
 5. The only thing that needs updating is the scroll handler in footer.html that references the old <header> element via $("header > div > a").

 Files to Modify (4 files, 0 new files)

 1. libs/header.html

 Replace old <header> element with the IOOS Web Components CDN script. Keep Google Analytics.

 ```html
 <!-- Google Analytics (keep as-is) -->
 <script async src="https://www.googletagmanager.com/gtag/js?id=G-ZSQZTQ1DE0"></script>
 <script>
   window.dataLayer = window.dataLayer || [];
   function gtag(){dataLayer.push(arguments);}
   gtag('js', new Date());
   gtag('config', 'G-ZSQZTQ1DE0');
 </script>
 <!-- IOOS UI Web Components -->
 <script src="https://dgd6r9iiqa8y9.cloudfront.net/ioos-ui-components.min.js"></script>
 ```

 Rationale: The <script> loads in <head> (via rmarkdown's in_header) so custom elements are defined before the browser encounters them in <body>. The old
 <header> element is removed.

 2. libs/footer.html

 Replace the entire file. Key changes:
 - Replace custom #footer div (46 lines of HTML) with <ioos-footer></ioos-footer>
 - Add <ioos-header></ioos-header> and use jQuery to prepend it to <body> top
 - Update scroll handler: old handler targeted $("header > div > a") which no longer exists; new handler measures <ioos-header> height dynamically
 - Preserve: image zoom, external-links-in-new-tab, navbar DOM rearrangement

 Scroll handler logic:
 - <ioos-header> renders an emblem bar (~55px) + IOOS nav (~50px) = ~105px total
 - When user scrolls past the IOOS header, fix the SanctSound .navbar at top
 - SanctSound .navbar z-index (1030) > IOOS header internal z-index (999), so it layers correctly

 3. libs/styles.css

 Remove dead CSS rules, update positioning:

 Lines: 1-9
 Rule: header > .container-fluid, header > .container-fluid a img
 Action: Remove (old header element gone)
 
 Lines: 116-134
 Rule: .custom-header, .custom-header .custom-logo, .custom-header .custom-logo img
 Action: Remove (unused)
 
 Lines: 136-142
 Rule: .navbar
 Action: Update: position: static; top: 0; (scroll handler manages fixation dynamically)
 
 Lines: 170-180
 Rule: .main-container
 Action: Update: margin-top: 0; (scroll handler manages margin dynamically)
 
 Lines: 193-318
 Rule: #footer, #footer-col-*, #footer path
 Action: Remove (Web Component owns its own styles via Shadow DOM)

 4. libs/infographiq.js

 No changes needed. Verified:
 - Tooltip div appended to <body> (line 2) -- unaffected
 - Modal HTML appended to <body> (line 19) -- unaffected
 - D3 event positioning (lines 153-154) -- document-relative, unaffected
 - Bootstrap modal show/hide (lines 127-137) -- z-index 1050 > IOOS header 999

 Files NOT modified

 - _site.yml -- no changes needed; in_header and after_body includes still used
 - _svg-html_child.Rmd -- loads infographiq.js, unaffected
 - libs/ioos_main.css -- not referenced in _site.yml, already inactive
 - libs/d3.v5.min.js -- unaffected

 Verification Plan

 After rendering the site with rmarkdown::render_site():

 1. IOOS header -- emblem banner + IOOS mega-menu (Data Access, Map Viewers, Regional Associations, Tools & Resources) appears at top of every page
 2. SanctSound navbar -- site navigation (Questions, Sanctuaries, Sounds, etc.) appears below IOOS header
 3. Scroll behavior -- scrolling past IOOS header fixes SanctSound navbar to viewport top
 4. SVG infographics -- open a sanctuary page (e.g., s_cinms.html), hover SVG elements for tooltips, click for modal popups
 5. Image zoom -- click any data-enlargeable image, verify overlay appears
 6. External links -- verify they open in new tabs
 7. IOOS footer -- standardized footer appears at bottom of every page
 8. Mobile -- verify IOOS header hamburger menu and SanctSound navbar collapse work

⏺ All four files have been updated. Here's a summary of the changes:
                                                                                
  libs/header.html                                                                                                                                                
                                                                                                                                                                  
  - Removed the old <header> element with IOOS emblem image                                                                                                       
  - Kept Google Analytics tags unchanged                                                                                                                          
  - Added <script src="https://dgd6r9iiqa8y9.cloudfront.net/ioos-ui-components.min.js"> to load IOOS Web Components                                               
                                                                                                                                                                  
  libs/footer.html                                                                                                                                                
                                                                                                                                                                  
  - Replaced 46-line custom #footer div with <ioos-footer></ioos-footer>
  - Added jQuery to prepend <ioos-header></ioos-header> to <body> top
  - Updated scroll handler: now measures <ioos-header> height dynamically instead of referencing the old $("header > div > a") selector
  - Preserved: image zoom, ESC key handling, external-links-in-new-tab, navbar DOM rearrangement

  libs/styles.css

  - Removed header>.container-fluid rules (old emblem styling)
  - Removed .custom-header rules (unused)
  - Removed all #footer / #footer-col-* / #footer path rules (126 lines -- Web Component owns its styles via Shadow DOM)
  - Changed .navbar from position: fixed; top: 93px to position: static; top: 0 (scroll handler manages fixation dynamically)
  - Changed .main-container from margin-top: 100px to margin-top: 0 (scroll handler manages margin dynamically)

  libs/infographiq.js

  - No changes needed (confirmed: tooltips, modals, D3 events all operate in light DOM, unaffected by Shadow DOM components)

  To verify, render the site with rmarkdown::render_site() and check the verification items from the plan (IOOS header/footer display, scroll behavior, SVG
  infographics, image zoom, external links, mobile).