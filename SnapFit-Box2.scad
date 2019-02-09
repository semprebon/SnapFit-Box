// Snap-fit Parametric Box

// The lid is held on by two ridges on the long (length) side that engage sockets on the base

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


size=[length, width, height];
minimum_thickness = round_to_layer_height(thickness);
gap = 2*layer_height;

/*
Round value to multiple of layer height
*/
function round_to_layer_height(x) = ceil(x / layer_height) * layer_height;

/*
Creates a snap-fit ridge (or socket) the top edge of which is at z, and protrudes toward x=0
at a distance of x along the x axis
*/
module ridge(x, z, entry_angle=45, exit_angle=45, length=10, height=minimum_thickness,
        width=gap*1.5, offset=0) {
    echo(x=x,z=z,length=length,height=height,width=width,offset=offset);
    translate([-x/2,0,z-height]) rotate([90,0,0]) translate([0, -height/2, 0]) linear_extrude(height=length, center=true) {
        offset(offset) polygon([[0,0], [width, width*sin(exit_angle)],
            [width, height-width*sin(entry_angle)], [0, height]]);
    }
}

/* test */
module side_cutout(size) {
    radius = 5;
    translate([-size.x/2-wall_thickness-gap,0,size.z+wall_thickness]) rotate([0,90,00])
        cylinder(r=radius, h=wall_thickness+2*gap);
}

module shell(size, thickness, bottom_thickness, bevel=0.2*wall_thickness) {
    _bottom_thickness = (bottom_thickness == undef) ? thickness : bottom_thickness;
    _outer_size = [size.x + 2*thickness, size.y + 2*thickness, size.z + thickness];
    translate([0, 0, _outer_size.z/2]) {
        difference() {
            hull() {
                cube(size=[_outer_size.x-bevel*2, _outer_size.y, _outer_size.z], center=true);
                cube(size=[_outer_size.x, _outer_size.y-bevel*2, _outer_size.z], center=true);
            }
            translate([0,0,_bottom_thickness/2]) cube(size=[size.x, size.y, size.z+thickness-_bottom_thickness], center=true);
        }
    }
}

/*
Creates a shell with a rim that is stepped.

size ([x,y,z]) - inner dimensions of the shell
thickness - thickness of the wall
step - width of the step (<thickness)
rise - how high the step rises from the rim. A negative value result in a step down from the rim
*/
module double_shell(size, thickness, step=undef, rise=undef, bevel=0.2*wall_thickness) {
    _inner_thickness = thickness-step;
    shell([size.x+2*_inner_thickness-gap, size.y+2*_inner_thickness-gap, size.z+_inner_thickness+rise], thickness=step+gap);
    translate([0,0,step]) shell(size, thickness=_inner_thickness, bottom_thickness=0);
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

size - inside dimensions of base of box
thickness - thickness of base walls
lid_depth - depth of the lid; if undef, compute a minimum lid size
ridge_offset - offset of the ridge from the rim of the box; if undef, compute a reasonable value
*/
module extended_lid_box(size, thickness, lid_depth, ridge_offset) {
    _ridge_height = minimum_thickness;
    _ridge_offset = (ridge_offset == undef) ? minimum_thickness : ridge_offset;
    _lid_depth = (lid_depth == undef) ? _ridge_offset + minimum_thickness + gap : lid_depth;
    _outer_size = [size.x+2*thickness, size.y+2*thickness, size.z + thickness];
    echo(_ridge_offset=_ridge_offset);

    // box
    if (part == "box" || part == "both") {
        difference() {
            shell(size, thickness=thickness);
            ridges(_outer_size.x, z=_outer_size.z-_ridge_offset, length=size.y/5, height=_ridge_height, expand=gap);
        }
    }

    // lid
    if (part == "base" || part == "both") {
        _lid_size = [_outer_size.x+2*gap, _outer_size.y+2*gap, _lid_depth];
        _lid_ridge_z = thickness + _ridge_offset + 2*gap + _ridge_height;
        translate([_lid_size.x+6*thickness,0,0]) {
            shell(_lid_size, thickness=thickness);
            ridges(_lid_size.x, z=_lid_ridge_z, length=size.y/5+2*gap, height=_ridge_height);
        }
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
/*
Create a box with lid that is flush with the outsde edge, with a stepped rim
*/
module inset_lid_box(size, thickness, lid_depth=undef, bevel=undef) {
    _bevel = (bevel == undef) ? 0.2*thickness : bevel;
    _ridge_height = minimum_thickness;
    _ridge_offset = minimum_thickness;
    _outer_size = [size.x+2*thickness, size.y+2*thickness, size.z + thickness];

    // base
    difference() {
        shell(size, thickness=thickness, step=thickness/2, rise=thickness, bevel=_bevel);
        ridges(-size.x, z=_outer_size.z-_ridge_offset, length=size.y/5, height=_ridge_height, expand=gap);
    }

    // lid
    _step_height = minimum_thickness + _ridge_offset + _ridge_height;
    _lid_size = [size.x-2*thickness, size.y-2*thickness, _step_height];
    _z = lid_depth + thickness + _step_height - _ridge_offset;
    translate([size.x+6*wall_thickness,0,0]) {
    //translate([0,0,_outer_size.z-_lid_size.z-thickness]) {
        double_shell(_lid_size, thickness=2*thickness, step=thickness+gap, rise=-_step_height, bevel=_bevel);
        ridges(-_lid_size.x - 2*thickness + 2*gap, z=_z, length=size.y/5, height=_ridge_height);
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

//double_shell(size, thickness=wall_thickness, step=1, rise=1);

cut_away() {
    extended_lid_box(size, thickness=thickness, lid_depth=size.z+thickness);
    //text(text="SW", size=12, font="Luckiest Guy:style=Regular", halign="center", valign="center");
//    resize([size.x-10, size.y-10]) circle(d=20, $fn=20);
    font = "Allerta Stencil:style=Regular";
    translate([size.x+6*wall_thickness+5,0]) rotate([0,0,30]) 2d_cube(40, 3);
    mirror([1,0,0]) {
        translate([0,15,0]) text(text="Savage", size=20, font=font, spacing=1, halign="center", valign="center");
        translate([0,-15,0]) text(text="Worlds", size=20, font=font, spacing=1, halign="center", valign="center");
    }
};

cut_away() {
    inset_lid_box(size, thickness=thickness, lid_depth=(size.x-size.z)-thickness);
    //text(text="SW", size=12, font="Luckiest Guy:style=Regular", halign="center", valign="center");
    circle(d=0.8*min(size.x, size.y), $fn=8);
    translate([size.x+6*thickness,0,0]) circle(d=0.8*min(size.x, size.y), $fn=5);
};

//ridge(x=-20,z=8.2,length=10,height=1.6,width=0.45, offset=0);
//ridge(x=0,z=8.2,length=10,height=1.6,width=0.45, offset=0);
//2d_cube(10,1);