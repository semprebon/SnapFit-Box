// Snap-fit Parametric Box

// The lid is held on by two ridges on the long (length) side that engage sockets on the base

inner_width = 20;
inner_length = 100;
inner_height = 10;
wall_thickness = 2;
gap = 0.3;

module ridge(x, z, entry_angle=45, exit_angle=45, length=10, height=wall_thickness/2, 
        width=gap*1.5, offset=0) {
    translate([-x/2,0,z-height/2]) rotate([90,0,0]) translate([0, -height/2, 0]) linear_extrude(height=length, center=true) {
        offset(offset) polygon([[0,0], [width, width*sin(exit_angle)], 
            [width, height-width*sin(entry_angle)], [0, height]]);
    }
}

module side_cutout(size) {
    radius = 5;
    translate([-size.x/2-wall_thickness-gap,0,size.z+wall_thickness]) rotate([0,90,00]) 
        cylinder(r=radius, h=wall_thickness+2*gap);
}

module shell(size, thickness, bevel=0.2*wall_thickness) {
    outer_size = [size.x + 2*thickness, size.y + 2*thickness, size.z + thickness];
    translate([0, 0, outer_size.z/2]) { 
        difference() {
            hull() {
                cube(size=[outer_size.x-bevel*2, outer_size.y, outer_size.z], center=true);
                cube(size=[outer_size.x, outer_size.y-bevel*2, outer_size.z], center=true);
            }    
            translate([0,0,thickness/2]) cube(size=size, center=true);
        }
    }
}

/*
 Creates a shell with a rim that is stepped.

 size ([x,y,z]) - inner dimensions of the shell
 step inset - inset of the step from the inner wall. A negative value indicates the step is from the outer wall
 rise - how high the step rises from the rim. A negative value result in a step down from the rim  
*/
module double_shell(size, step_inset=undef, step_rise=undef, bevel=0.2*wall_thickness) {
    inner_size = [size.x, size.y, size.z + 
    shell(size, 
}

module base(size, lid_size) {
    x = size.x+2*wall_thickness;
    difference() {
        shell(size, thickness=wall_thickness);
        offset = gap;
        z = size.z+wall_thickness/2+gap;
        ridge(x=x, z=z, length=10, offset=offset);
        mirror([1,0,0]) ridge(x=x, z=z, length=10, offset=gap);
    }
}

module lid(size) {
    z = 2*wall_thickness + gap;
    shell([size.x, size.y, z-wall_thickness], thickness=wall_thickness);
    ridge(size.x, z=z, length=10);
    mirror([1,0,0]) ridge(size.x, z=z, length=10);
}

module box(size) {
    lid_size = [size.x+2*wall_thickness+2*gap, 
            size.y+2*wall_thickness+2*gap, 
            3.5*wall_thickness];
    base(size, lid_size);
    translate([size.x+6*wall_thickness,0,0]) lid(lid_size);
}

box([inner_width,inner_length,inner_height]);