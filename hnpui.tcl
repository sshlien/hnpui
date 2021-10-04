
#package provide app-hnpgui 1.0
#!/bin/sh
# the next line restarts using wish \
exec wish "$0" "$@"

set hnpguipath [pwd]
#puts $kernfiles

wm protocol . WM_DELETE_WINDOW {
    get_geometry_of_all_toplevels
    write_hnpgui_ini 
    exit
    }

source tooltip.tcl


# init_kernstate
# position_window (window)
# get_geometry_of_all_toplevels
# write_hnpgui_ini
# read_hnpgui_ini
#  .header buttons interface
# select_folder
# cfg_settings
# load_collections
# selected_tune
# create_html_header
# load_kern_file
# copy_kern_to_html
# export_to_browser
# make_editor
# BindYview (lists args)
# get_header (file)
# verovio_options
# get_verovio_options


proc init_kernstate {} {
global kernstate
   set kernstate(infolder) ""
   set kernstate(infile) ""
   set kernstate(browser) "firefox"
   set kernstate(tempfile) "[pwd]/tune.html"
   set kernstate(.cfg) ""
   set kernstate(.edit) ""
   set kernstate(.headr) ""
   set kernstate(.voptions) ""
   set kernstate(pwidth) ""
   set kernstate(mbot) ""
   set kernstate(mleft) ""
   set kernstate(mright) ""
   set kernstate(mtop) ""
   set kernstate(sca) ""
   set kernstate(spstaff) ""
   set kernstate(splin) ""
   set kernstate(spnline) ""
   set kernstate(appendtext) 0
   set kernstate(autoresize) 0
   set kernstate(header) 0
   set kernstate(incipit) 0
}

init_kernstate

proc position_window {window} {
   global kernstate
   if {[string length $kernstate($window)] < 1} return
   wm geometry $window $kernstate($window)
   }

proc get_geometry_of_all_toplevels {} {
   global kernstate
   set toplevellist {"." ".edit" ".headr" ".voptions" ".cfg"}
   foreach top $toplevellist {
    if {[winfo exist $top]} {
      set g [wm geometry $top]
      scan $g "%dx%d+%d+%d" w h x y
      #puts "$top $x $y"
      set kernstate($top) +$x+$y
      }
   }
}

proc write_hnpgui_ini {} {
    global kernstate
    global hnpguipath
    set outfile [file join $hnpguipath hnpgui.ini]
    set handle [open $outfile w]
    #tk_messageBox -message "writing $outfile"  -type ok
    foreach item [lsort [array names kernstate]] {
        puts $handle "$item $kernstate($item)"
    }
    close $handle
}

proc read_hnpgui_ini {hnpguipath} {
    global kernstate 
    set infile [file join $hnpguipath hnpgui.ini]
    if {![file exist $infile]} return
    set handle [open $infile r]
    #tk_messageBox -message "reading $infile"  -type ok
    while {[gets $handle line] >= 0} {
        set error_return [catch {set n [llength $line]} error_out]
        if {$error_return} continue
        set contents ""
        set param [lindex $line 0]
        for {set i 1} {$i < $n} {incr i} {
            set contents [concat $contents [lindex $line $i]]
        }
        #if param is not already a member of the kernstate array
        # (set by kern_init), then we ignore it. This prevents
        # kernstate array filling up
        #with obsolete parameters used in older versions of the program.
        set member [array names kernstate $param]
        if [llength $member] { set kernstate($param) $contents }
    }
}


read_hnpgui_ini $hnpguipath 

set w .header
frame $w
button $w.render -text render -command {copy_kern_to_html; 
   export_to_browser}
button $w.edit -text view -command make_editor
button $w.options -text options -command verovio_options
button $w.open -text open -command select_folder
button $w.cfg -text cfg -command cfg_settings

pack $w.open $w.cfg $w.edit $w.options $w.render -side left

pack $w

tooltip::tooltip .header.open  "Selects kern folder to open"
tooltip::tooltip .header.cfg "Select browser and temporary html file to use"
tooltip::tooltip .header.edit "Views selected kern file.\nEditor not implemented yet."
tooltip::tooltip .header.options "Specify page dimensions, scale factor
 and other options used by jnp."
tooltip::tooltip .header.render "Creates html with kern file embedded
 and sends it to browser.  Can take 20 
seconds to typeset the music."

set w .collection
frame .collection
label .collection.folder -text $kernstate(infolder) -width 40
listbox .collection.list -height 15 -width 60 -bg lightyellow\
    -yscrollcommand {.collection.ysbar set} -selectmode single 
scrollbar .collection.ysbar -orient vertical -command {.collection.list yview}
pack $w.folder
pack $w.list -side left  -fill y
pack $w.ysbar -side right   -fill y -in $w
pack $w -expand 1 -fill both

proc select_folder {} {
global kernstate
 set folder [tk_chooseDirectory -title "Choose the directory containing the abc files" -initialdir $kernstate(infolder)]
    if {[llength $folder] < 1} return
set kernstate(infolder) $folder
load_collection
}

proc cfg_settings {} {
set w .cfg
if {[winfo exist .cfg]} {return}
toplevel .cfg
position_window ".cfg"
button $w.browserbut -text "find or enter browser"  -command pick_browser
entry $w.browserent -width 50 -textvariable kernstate(browser) 
button $w.tempfilebut -text "find or enter temp html file" -command pick_tempfile
entry $w.tempfilent -width 50 -textvariable kernstate(tempfile)
grid $w.browserbut $w.browserent
grid $w.tempfilebut $w.tempfilent
}

proc pick_browser {} {
global kernstate
set openfile [tk_getOpenFile]
if {[string length $openfile] > 1} {
   set kernstate(browser) $openfile
   }
}

proc pick_tempfile {} {
global kernstate
set filedir [pwd]
set openfile [tk_getOpenFile -initialdir $filedir ]
if {[string length $openfile] > 1} {
   set kernstate(tempfile) $openfile
   }
}

proc load_collection {} {
  global kernstate
  set w .collection
  $w.list delete 0 end
  set hnpguipath [pwd]
  set infolder $kernstate(infolder)
  if {![file exist $infolder]} return
  cd $infolder
  set kernfiles [glob *.krn]
  cd $hnpguipath
  set kernfiles [lsort $kernfiles]
  foreach kern $kernfiles {
    $w.list insert end $kern
   }
  $w.list selection set 0
  }

load_collection

proc selected_tune {} {
global kernstate
set infolder $kernstate(infolder)
set index [.collection.list curselection]
set infile $infolder/[.collection.list get $index]
puts $infile
set kernstate(infile) $infile
return $infile
}

proc create_html_header {title fileroot} {
set displayoptions [get_verovio_options]
set html_preamble "<!DOCTYPE HTML>\n<html>
<html>
<head>
<title>An example</title>
<script src=\"https://plugin.humdrum.org/scripts/humdrum-notation-plugin-worker.js\"></script>
</head>
<body>
<p>$title</p>

<script>
   displayHumdrum({
      source: \"$fileroot\",
      $displayoptions 
   });
</script>

<script type=\"text/x-humdrum\" id=\"$fileroot\">
"
}

proc load_kern_file {infile} {
set inhandle [open $infile r]
set kern [read $inhandle]
close $inhandle
return $kern
}

proc copy_kern_to_html {} {
  global kernstate
  set infile [selected_tune]
  set fileroot [file tail $infile]
  set fileroot [file rootname $fileroot]
  set outhandle [open $kernstate(tempfile) w]
  puts $outhandle [create_html_header $fileroot $fileroot]
  puts $outhandle [load_kern_file $infile]
  puts $outhandle "</script>\n</body>\n</html>"
  close $outhandle
  }

proc export_to_browser {} {
    global kernstate
    #puts "$kernstate(browser) file://$kernstate(tempfile)"
    exec $kernstate(browser) file://$kernstate(tempfile) &
    }


proc make_editor {} {
set infile [selected_tune]
set nboxes [get_header $infile]
set w .edit
if {[winfo exist .edit]} {destroy .edit}
toplevel .edit
position_window ".edit"
set listboxes {}
for {set i 0} {$i < $nboxes} {incr i} {
   listbox $w.list$i -height 10 -width 10 -yscrollcommand {.edit.ysbar set}
   pack $w.list$i -side left
   lappend listboxes $w.list$i
   }
scrollbar .edit.ysbar -orient vertical -command [list BindYview $listboxes]
pack .edit.ysbar -side right   -fill y -in $w

set kerndata [load_kern_file $infile]
foreach line [split $kerndata '\n'] {
  set spines [split $line '\t']
  set nspines [llength $spines]
  if {$nspines > 0} {
    for {set i 0} {$i < $nspines} {incr i} {
      set elem [lindex $spines $i]
      if {$i < $nboxes && [string first "!!!" $elem] != 0} {
           $w.list$i insert end $elem
             } 
      }
    }
  }
}

proc BindYview {lists args} {
  #puts "lists = $lists args = $args"
  foreach l $lists {
    eval {$l yview} $args 
    } 
  }

proc get_header {infile} {
global kernstate
if {[winfo exist .headr] == 1} {
  .headr.t delete 1.0 end } else {
   toplevel .headr
   position_window ".headr"
   text .headr.t -width 50 -yscrollcommand {.headr.ysbar set}
   scrollbar .headr.ysbar -orient vertical -command {.headr.t yview}
   pack .headr.t -side left
   pack .headr.ysbar  -side right -fill y -in .headr
   }
set kerndata [load_kern_file $infile]
set maxspines 0
foreach line [split $kerndata '\n'] {
  set spines [split $line '\t']
  set nspines [llength $spines]
  set maxspines [expr max($nspines,$maxspines)]
  if {[string first "!!!" $line] == 0} {
    .headr.t insert end $line\n
    }
  }
return $maxspines
}

proc verovio_options {} {
global kernstate
if {![info exist .voptions]} {
  set w .voptions
  if {[winfo exist $]} {return}
  toplevel $w
  position_window ".voptions"
  label $w.pwidth -text "Page width"
  tooltip::tooltip .voptions.pwidth "minimum 100, maximum 60000"  
  entry $w.pwidthe -textvariable kernstate(pwidth)
  label $w.mbot -text "Bottom margin"
  tooltip::tooltip .voptions.mbot "default 50, minimum 0, maximum 500"
  entry $w.mbote -textvariable kernstate(mbot)
  label $w.mleft -text "Left margin"
  tooltip::tooltip .voptions.mleft "default 50, minimum 0, maximum 500"
  entry $w.mlefte -textvariable kernstate(mleft)
  label $w.mright -text "Right margin"
  tooltip::tooltip .voptions.mright "default 50, minimum 0, maximum 500"
  entry $w.mrighte -textvariable kernstate(mright)
  label $w.mtop -text "Top margin"
  tooltip::tooltip .voptions.mtop "default 50, minimum 0, maximum 500"
  entry $w.mtope -textvariable kernstate(mtop) 
  label $w.sca -text "Scale"
  tooltip::tooltip .voptions.sca "scale factor as a percentage\
default 40, minimum 1"
  entry $w.scae -textvariable kernstate(sca)
  label $w.spstaff -text "Staff spacing"
  tooltip::tooltip .voptions.spstaff "default 8, minimum 0, maximum 24"
  entry $w.spstaffe -textvariable kernstate(spstaff)
  label $w.splin -text "Linear spacing"
  tooltip::tooltip .voptions.splin "default 0.25, minimum 0.0, maximum 1.0"
  entry $w.spline -textvariable kernstate(splin) 
  label $w.spnlin -text "Nonlinear spacing"
  tooltip::tooltip .voptions.spnlin "default 0.6, minimum 0.0, maximum 1.0"
  entry $w.spnline -textvariable kernstate(spnline)
  checkbutton $w.autoresize -variable kernstate(autoresize)\
      -text "auto resize" -onvalue true -offvalue false
  tooltip::tooltip .voptions.autoresize "re-typeset music when browser window is resized"
  checkbutton $w.header -variable kernstate(header) -text header\
      -onvalue true -offvalue false
  tooltip::tooltip .voptions.header "include title, composer and other info"
  checkbutton $w.incipit -variable kernstate(incipit)\
      -text incipit -onvalue true -offvalue false
  tooltip::tooltip .voptions.incipit "display only first system of music score" 
  grid $w.pwidth $w.pwidthe $w.sca $w.scae
  grid $w.mbot $w.mbote $w.mtop $w.mtope
  grid $w.mleft $w.mlefte $w.mright $w.mrighte
  grid $w.spstaff $w.spstaffe 
  grid $w.splin $w.spline $w.spnlin $w.spnline
  grid $w.autoresize $w.header $w.incipit
  }
}

proc get_verovio_options {} {
global kernstate
global numericOptions
set w .voptions
set voptionlist {pwidth mbot mleft mright mtop sca spstaff\
          splin spnline autoresize header incipit}
set opstring ""
foreach op $voptionlist {
   if  {[string length [string trim $kernstate($op) " "]] > 0} {
     set optioname [lindex $numericOptions($op) 0]
     append opstring "\n      $optioname:  $kernstate($op),"
     }
  }
set opstring [string trimright $opstring ,]
#set opstring [string trimleft $opstring \n]
return $opstring
}




# Options
array set  numericOptions {
  pwidth {pageWidth none 100 60000}
  mbot {pageMarginBottom 50 0 500}
  mleft {pageMarginLeft 50 0 500}
  mright {pageMarginRight 50 0 500}
  mtop {pageMarginTop 50 0 500}
  sca {scale 40 1}
  spstaff {spacingStaff 8 0 24} 
  splin {spacingLinear 0.25 0.0 1.0}
  spnline {spacingNonLinear 0.6 0.0 1.0}
  autoresize {autoResize}
  header {header}
  incipit {incipit}
  }

set nonNumericOptionList {
  appendText
  {autoResize false}
  filter 
  {header false}
  {incipit false}
  postFunction
  postFunctionHumdrum
  source
  {suppressSvg false}
  }

