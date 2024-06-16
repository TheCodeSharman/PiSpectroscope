
// Configuration
light_distance_mm = 50; // distance from slit to diffraction grating
diffraction_grating_angle = 30; // angle of light to diffraction grating
diffraction_grating_mm = [ 15, 15, 1 ]; // [width, height, depth] of diffratcion grating
slit_mm = [10,0.2]; // the [width,height] of the slit
lense_mm = [ 30, 12 ]; // [ height, diameter ] of lense
camera_board_mm = [ 45, 45, 4 ]; // [ width, height, depth ] of camera board
camera_board_clearance = 2; // clearance to allow cabling etc.
camera_cable_mm = [ 30, 100, 1 ]; // [ width,length, depth ] of cable to raspberry pi
screw_size_mm=4;

// Other constants
fillet_radius = 0.5; // radius used for rounded courners
wall_thickness = 2; // thickness of walls
clearance = 0.4; // clearance added to make parts fit

assemble = false; // set to false for eport to STL
explode_lid = 50; // offset vertically to explode the lid

// Dependent parameters
camera_plus_board = camera_board_mm[2] + lense_mm[0];
case_fillet = fillet_radius*10;
enclosure_mm = [camera_board_mm[0]-case_fillet*+clearance*2+camera_board_clearance*2, light_distance_mm+camera_plus_board, camera_board_mm[1]*1.2+2*(wall_thickness+clearance)];

// adds a value to each member of an array
function array_add(arr, value) = [for (elem = arr) elem + value];

// sums two arrays of the same size
function array_sum(arr1, arr2) = [for (i = [0:len(arr1)-1]) arr1[i] + arr2[i]];

module fillet_cube(size,center) {
    translate([(center?0:fillet_radius),(center?0:fillet_radius),(center?-size[2]/2:0)])
    linear_extrude(size[2])
        offset(fillet_radius) 
            square(size=[size[0]-fillet_radius*2,size[1]-fillet_radius*2],center=center);
}

module place_in_corners(size,offset=0,center=false) {
    translate(center?[-size[0]/2,-size[1]/2,-size[2]/2]:[0,0,0]) {
        translate([size[0]+offset,size[1]+offset,0]) children();
        translate([-offset,size[1]+offset,0]) children();
        translate([size[0]+offset,-offset,0]) children();
        translate([-offset,-offset,0]) children();
    }
}

module drill_corner_holes(size,d,offset=0,center=false) {
    difference() {
        union() {
            children();
        }
        place_in_corners(size,offset,center) {
            cylinder(h=size[2],d=d);
        }
    }
}


module lense(buffer=0) {
    color("red",0.1) cylinder(h = lense_mm[0], d = lense_mm[1]+buffer);
}

module diffraction_grating(buffer=0) {
    color("blue") cube(array_add(diffraction_grating_mm, buffer), center=true);
}

// A model of the camera with lense attached - the lense is just attached
// without being offset for simplicity.
module camera_board() {
    color("green", 0.1) 
    translate([0,0,camera_board_mm[2]/2]) {
        drill_corner_holes(camera_board_mm, screw_size_mm, -screw_size_mm, center=true) {
            cube(camera_board_mm, center=true);
        }
    }
}

module camera_cable() {
    color("white",0.5) cube(camera_cable_mm, center=true);
}

module camera() {
    camera_board();
    translate([0,0,camera_board_mm[2]]) lense();
}

module grating_holder_connector(width,height) {
     lense_cover_mm = [lense_mm[0]/2, lense_mm[1]+wall_thickness];
     base_mm = [width,lense_cover_mm[1]/10];
     translate([0,0,-lense_cover_mm[0]])
     linear_extrude(lense_cover_mm[0]) {
        hull() {
            circle(d=lense_cover_mm[1]);
            translate([0,-height+base_mm[1]/2,0])
                offset(fillet_radius) square(size=[base_mm[0]-fillet_radius*2,base_mm[1]-fillet_radius*2], center=true);
        }

    }
}

// A way to hold the DVD grating 
module grating_holder() {
    grating_holder_mm = [ diffraction_grating_mm[0] + 5, diffraction_grating_mm[1] + 5, diffraction_grating_mm[2]*3 ];
    translate([0,0,-grating_holder_mm[2]/2])
    difference() {
        union() {
            fillet_cube(grating_holder_mm, center=true);
            grating_holder_connector(grating_holder_mm[0], grating_holder_mm[1]/2);
        }
        color("purple") 
        translate([0,0,-lense_mm[0]+grating_holder_mm[2]]) lense(clearance);
        scale([2,1,1]) diffraction_grating(clearance);
    }
}

// Attach the camera to the grating holder and grating, this is to give a visual construction
// aid in order to see if the varioous components fit together correctly.
module camera_with_grating() {
    grating_holder();
    translate([0,0,-diffraction_grating_mm[2]*1.5])
    diffraction_grating();

    translate([0,0,-(camera_board_mm[2] + lense_mm[0])]) 
    camera();
}

// The 3d extrusion shape used to create the 3d enclosure
module enclose_base(fillet) {
    offset(fillet) square([enclosure_mm[0],enclosure_mm[1]], center=true);
}

module enclosure_lid() {
    color("cyan",0.5)
    translate([0,enclosure_mm[1]/2,0])
    drill_corner_holes([enclosure_mm[0],enclosure_mm[1],wall_thickness*2],screw_size_mm,center=true) {
        union() {
            linear_extrude(wall_thickness) {
                enclose_base(case_fillet);
            }
            translate([0,0,-wall_thickness])
            linear_extrude(wall_thickness) {
                enclose_base(case_fillet-wall_thickness);
            }
        }
    }
}

module enclosure_construction_bottom(fillet) {
    color("red",0.5)
    
    linear_extrude(enclosure_mm[2]) {
        enclose_base(fillet);
    }
}

module enclosure_bottom() {
    difference() {
        translate([0,enclosure_mm[1]/2,enclosure_mm[2]/2+wall_thickness])
        drill_corner_holes(enclosure_mm,screw_size_mm,center=true) {
            translate([0,0,-wall_thickness])
            union() {
                translate([0,0,-enclosure_mm[2]/2]) 
                    difference() {
                        enclosure_construction_bottom(case_fillet);
                        translate([0,0,wall_thickness])
                        enclosure_construction_bottom(case_fillet-wall_thickness);
                    }
                place_in_corners(enclosure_mm,center=true) {
                    color("purple",0.5)
                    cylinder(h=enclosure_mm[2]-wall_thickness-clearance,d=screw_size_mm+wall_thickness);
                }
            }
        }
        translate([0,-camera_cable_mm[1]/2+camera_board_mm[1],wall_thickness+clearance*2])
        camera_cable();
        light_beam();
    }
}

module light_beam() {
    beam_position = [light_distance_mm/2+camera_plus_board+wall_thickness*2,
    lense_mm[0] + lense_mm[0]*0.6*cos(diffraction_grating_angle)];
    
    translate([0,beam_position[0],beam_position[1]])
        color("orange",0.5) 
            cube([slit_mm[0],light_distance_mm,slit_mm[1]],center=true);

    translate([0,beam_position[0]+light_distance_mm,beam_position[1]])
        color("white",0.5)
            cube([slit_mm[0],light_distance_mm,slit_mm[1]],center=true);
}

if ( assemble ) {
    // we're assuming the light is coming from the positive y direction
    translate([0,camera_plus_board*cos(diffraction_grating_angle)+case_fillet+camera_board_clearance + screw_size_mm+wall_thickness,wall_thickness+clearance*2+camera_cable_mm[2]])
        rotate([-diffraction_grating_angle,0,0])
            translate([0,-camera_board_mm[1]/2,camera_plus_board])
                camera_with_grating();
    translate([0,-camera_cable_mm[1]/2+camera_board_mm[1],wall_thickness+clearance*2])
        camera_cable();

    enclosure_bottom();
    translate([0,0,enclosure_mm[2]+explode_lid]) enclosure_lid();

    light_beam();
} else {
    translate([-enclosure_mm[0]-10,enclosure_mm[1]/2,0]) rotate([0,180,0]) grating_holder();
    translate([enclosure_mm[0]+30,0,0]) enclosure_bottom();
    translate([0,0,wall_thickness]) rotate([0,180,0]) enclosure_lid();
}




