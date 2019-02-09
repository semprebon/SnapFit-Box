// Snap-fit Parametric Box

use <utils/build_plate.scad>
/*
 The lid is held on by two ridges on the long (length) side that engage sockets on the box.
 In this version, theld extends beyond the edges of the box.

/* [Global] */

/* Length of interior of box (mm) */
length = 94; // [20:400]
/* Width of interior of box (mm) */
width = 69; // [20:400]
/* Height of interior of box (mm) */
height = 19; // [10:400]
/* Thickness of walls (mm) */
thickness = 1.5; // [0.8:6.0]
/* Layer height you plan to print at (mm) */
layer_height = 0.16;
/* Box or lid? */
part = "both"; // [box:Box Only,lid:Lid Only,both:Both Box and Lid]
/* depth of inside of lid. This will be increased to a sufficient size to include the ridge-lock if too small */
lid_depth = 20.5; // [3:400]

/* [Lid Detail] */

/* lid text */
lid_text = "BOX";
/* lid font */
lid_font = "Allerta Stencil";
/* lid text effect */
lid_text_effect = "inscribed"; // [inscribed,cut through]

/* [Display] */

//for display only, doesn't contribute to final object
build_plate_selector = 3; //[0:Replicator 2,1: Replicator,2:Thingomatic,3:Manual]

//when Build Plate Selector is set to "manual" this controls the build plate x dimension
build_plate_manual_x = 220; //[100:400]

//when Build Plate Selector is set to "manual" this controls the build plate y dimension
build_plate_manual_y = 220; //[100:400]

build_plate(build_plate_selector,build_plate_manual_x,build_plate_manual_y);

size=[length, width, height];
minimum_thickness = round_to_layer_height(thickness);
gap = 2*layer_height;
ridge_height = minimum_thickness;
ridge_offset = minimum_thickness;
minimum_lid_depth = ridge_offset + minimum_thickness + gap;
maximum_lid_depth = height + thickness + gap;
actual_lid_depth = min(maximum_lid_depth, max(minimum_lid_depth, lid_depth));

/*
Round value to multiple of layer height
*/
function round_to_layer_height(x) = ceil(x / layer_height) * layer_height;

/*
Compute the outer size of a shell with given inner size and thickness
*/
function outer_size(size, thickness) = [size.x+2*thickness, size.y+2*thickness, size.z + thickness];

/*
Creates a snap-fit ridge (or socket) the top edge of which is at z, and protrudes toward x=0
at a distance of x along the x axis
*/
module ridge(x, z, entry_angle=45, exit_angle=45, length=10, height=minimum_thickness,
        width=gap*1.5, offset=0) {

    translate([-x/2,0,z-height]) rotate([90,0,0]) translate([0, -height/2, 0]) linear_extrude(height=length, center=true) {
        offset(offset) polygon([[0,0], [width, width*sin(exit_angle)], 
            [width, height-width*sin(entry_angle)], [0, height]]);
    }
}

/* test */
module side_cutout(size) {
    radius = 5;
    translate([-size.x/2-thickness-gap,0,size.z+thickness]) rotate([0,90,00])
        cylinder(r=radius, h=thickness+2*gap);
}

module shell(size, thickness, bottom_thickness, bevel=0.2*thickness) {
    _bottom_thickness = (bottom_thickness == undef) ? thickness : bottom_thickness;
    _outer_size = [size.x + 2*thickness, size.y + 2*thickness, size.z + thickness];
    difference() {
        translate([0, 0, _outer_size.z/2]) {
            hull() {
                cube(size=[_outer_size.x-bevel*2, _outer_size.y, _outer_size.z], center=true);
                cube(size=[_outer_size.x, _outer_size.y-bevel*2, _outer_size.z], center=true);
            }
        }
        translate([-size.x/2,-size.y/2,_bottom_thickness]) cube(size=[size.x, size.y, size.z+2*thickness]);
    }
}

/*
create a pair of ridges on a shell

x - position of wall face socket should be placed on
z - height of top edge of ridge
length - length of ridge along y axis
expand - amount expand dimensions of ridge by for fit
*/
module ridges(x, z, length, height=minimum_thickness, expand=0) {
    ridge(x=x, z=z, length=length, offset=expand, height=height);
    mirror([1,0,0]) ridge(x=x, z=z, length=length, offset=expand);
}


/*
Create a simple box with a single shell for the base and lid. The lid extends in the
x/y directions so the base can just fit into it.

thickness - thickness of box walls
ridge_offset - offset of the ridge from the rim of the box
*/
module box(size, thickness, ridge_offset) {
    _outer_size = outer_size(size, thickness);

    // box
    difference() {
        shell(size, thickness=thickness);
        ridges(_outer_size.x, z=_outer_size.z-ridge_offset, length=size.y/5, height=ridge_height, expand=gap);
    }
}

/*
Create a simple box with a single shell for the base and lid. The lid extends in the
x/y directions so the base can just fit into it.

size - inside dimensions of lid
thickness - thickness of base walls
lid_depth - depth of the lid; if undef, compute a minimum lid size
ridge_offset - offset of the ridge from the rim of the box; if undef, compute a reasonable value
*/
module lid(size, thickness) {

    // lid
    if (part == "base" || part == "both") {
        _lid_ridge_z = thickness + _ridge_offset + 2*gap + _ridge_height;
        //translate([_lid_size.x+6*thickness,0,0]) {
            shell(size, thickness=thickness);
            ridges(size.x, z=_lid_ridge_z, length=size.y/5+2*gap, height=ridge_height);
        //}
    }
}

module cut_away() {
    difference() {
        children(0);
        union() {
            linear_extrude(height=1000, center=true) children([1:$children-1]);
        }
    }
}
module rhombus(side) {
    dx = side*sqrt(3)/2;
    dy = side/2;
    polygon([[0,0],[dx,dy],[0,2*dy],[-dx,dy]]);
}

module 2d_cube(side, thickness) {
    t = thickness*sqrt(3)/2;
    for (a = [0, 120, 240]) {
        rotate([0,0,a]) translate([0,thickness]) rhombus(side-t);
    }
}

/**
Arrange parts of given size along the x axis
*/
module distribute_parts(size, separation=5) {
    _start = -($children * size)/2;
    _spacing = size + separation;
    for (i=[0:1:$children-1]) {
        translate([_start + i*_spacing,0,0]) children(i);
    }
}

//double_shell(size, thickness=wall_thickness, step=1, rise=1);

cut_away() {
    box(size, thickness=thickness, ridge_offset);

    lid([outer_size(size).x+2*gap, outer_size(size).y+2*gap, lid_depth], thickness=thickness, ridge_offset);
    //text(text="SW", size=12, font="Luckiest Guy:style=Regular", halign="center", valign="center");
//    resize([size.x-10, size.y-10]) circle(d=20, $fn=20);
    font = "Allerta Stencil:style=Regular";
    translate([size.x+6*thickness+5,0]) rotate([0,0,30]) 2d_cube(40, 3);
    mirror([1,0,0]) {
        translate([0,15,0]) text(text="Savage", size=20, font=font, spacing=1, halign="center", valign="center");
        translate([0,-15,0]) text(text="Worlds", size=20, font=font, spacing=1, halign="center", valign="center");
    }
};
