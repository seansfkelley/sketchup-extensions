module ShakerCabinets
  def self.add_shaker_cabinet
    model = Sketchup.active_model

    parameter_names = [
      'Style',
      'Carcass Width',
      'Carcass Height',
      'Carcass Depth',
      'Face Border Width',
      'Face Depth',
      'Face Inset Depth',
      'Handle Type',
      'Handle Position',
    ]
    hardcoded_parameter_defaults = [
      'Shaker',
      24.inch,
      24.inch,
      24.inch,
      2.inch,
      1.inch,
      (1.to_f / 2).inch,
      'Pull',
      'Center',
    ]
    parameter_defaults = []

    attribute_storage = model.attribute_dictionary 'Shaker Cabinets configuration', true
    parameter_names.each_index do |i|
      value = attribute_storage[parameter_names[i]]
      if value.nil?
        parameter_defaults << hardcoded_parameter_defaults[i]
      else
        parameter_defaults << value
      end
    end

    inputs = UI.inputbox(
      parameter_names,
      parameter_defaults,
      ['Shaker|Plain', '', '', '', '', '', '', 'None|Pull|Knob', 'Top Left|Top Center|Top Right|Left|Center|Right|Bottom Left|Bottom Center|Bottom Right']
    )

    return unless inputs

    parameter_names.each_index do |i|
      attribute_storage[parameter_names[i]] = inputs[i]
    end

    style, carcass_width, carcass_height, carcass_depth, face_border_width, face_depth, face_inset_depth, handle_type, handle_location = inputs

    model.start_operation('Draw Shaker Cabinet')
    cabinet = model.definitions.add('Shaker Cabinet')

    ShakerCabinets::draw_carcass cabinet.entities, carcass_width, carcass_height, carcass_depth
    case style
    when 'Shaker'
      ShakerCabinets::draw_shaker_face cabinet.entities, carcass_width, carcass_height, face_border_width, face_depth, face_inset_depth
    when 'Plain'
      ShakerCabinets::draw_simple_face cabinet.entities, carcass_width, carcass_height, face_depth
    end

    handle_point, handle_orientation = case handle_location
    when 'Top Left'
      [Geom::Point3d.new(face_border_width / 2, -face_depth, carcass_height - face_border_width), :vertical_top]
    when 'Top Center'
      [Geom::Point3d.new(carcass_width / 2, -face_depth, carcass_height - face_border_width / 2), :horizontal]
    when 'Top Right'
      [Geom::Point3d.new(carcass_width - face_border_width / 2, -face_depth, carcass_height - face_border_width), :vertical_top]
    when 'Left'
      [Geom::Point3d.new(face_border_width / 2, -face_depth, carcass_height / 2), :vertical]
    when 'Center'
      if style == 'Plain'
        [Geom::Point3d.new(carcass_width / 2, -face_depth, carcass_height / 2), :horizontal]
      else
        [Geom::Point3d.new(carcass_width / 2, -face_depth + face_inset_depth, carcass_height / 2), :horizontal]
      end
    when 'Right'
      [Geom::Point3d.new(carcass_width - face_border_width / 2, -face_depth, carcass_height / 2), :vertical]
    when 'Bottom Left'
      [Geom::Point3d.new(face_border_width / 2, -face_depth, face_border_width), :vertical_bottom]
    when 'Bottom Center'
      [Geom::Point3d.new(carcass_width / 2, -face_depth, face_border_width / 2), :horizontal]
    when 'Bottom Right'
      [Geom::Point3d.new(carcass_width - face_border_width / 2, -face_depth, face_border_width), :vertical_bottom]
    end

    case handle_type
    when 'None'
      # nothing
    when 'Knob'
      ShakerCabinets::draw_knob cabinet.entities, handle_point, handle_orientation
    when 'Pull'
      ShakerCabinets::draw_pull cabinet.entities, handle_point, handle_orientation
    end

    camera = model.active_view.camera

    if camera.direction.x.abs >= camera.direction.y.abs
      if camera.direction.x > 0
        rotation = Geom::Transformation.rotation ORIGIN, Z_AXIS, 270.degrees
      else
        rotation = Geom::Transformation.rotation ORIGIN, Z_AXIS, 90.degrees
      end
    else
      if camera.direction.y > 0
        rotation = IDENTITY
      else
        rotation = Geom::Transformation.rotation ORIGIN, Z_AXIS, 180.degrees
      end
    end

    translation = Geom::Transformation.translation([-carcass_width / 2, -carcass_depth / 2, -carcass_height / 2]) *
      Geom::Transformation.translation(camera.eye.offset(camera.direction, (10 * 12).inch))

    model.active_entities.add_instance cabinet, translation * rotation

    model.commit_operation
  end

  def self.draw_carcass(entities, width, height, depth)
    face = entities.add_face [
      [0,     0, 0],
      [width, 0, 0],
      [width, 0, height],
      [0,     0, height],
    ]
    face.reverse! unless face.normal.samedirection?(Y_AXIS)
    face.pushpull depth
  end

  def self.draw_shaker_face(entities, carcass_width, carcass_height, face_border_width, face_depth, face_inset_depth)
    face = entities.add_face [
      [0,             -face_depth, 0],
      [carcass_width, -face_depth, 0],
      [carcass_width, -face_depth, carcass_height],
      [0,             -face_depth, carcass_height],
    ]
    face.reverse! unless face.normal.samedirection?(Y_AXIS)
    face.pushpull face_depth

    face = entities.add_face [
      [face_border_width,                 -face_depth, face_border_width],
      [carcass_width - face_border_width, -face_depth, face_border_width],
      [carcass_width - face_border_width, -face_depth, carcass_height - face_border_width],
      [face_border_width,                 -face_depth, carcass_height - face_border_width],
    ]

    face.reverse! unless face.normal.samedirection?(Y_AXIS.reverse)
    face.pushpull -face_inset_depth
  end

  def self.draw_simple_face(entities, carcass_width, carcass_height, face_depth)
    face = entities.add_face [
      [0,             -face_depth, 0],
      [carcass_width, -face_depth, 0],
      [carcass_width, -face_depth, carcass_height],
      [0,             -face_depth, carcass_height],
    ]
    face.reverse! unless face.normal.samedirection?(Y_AXIS)
    face.pushpull face_depth
  end

  def self.draw_knob(entities, point, orientation)
    circle = entities.add_circle point, Y_AXIS.reverse, (1.to_f / 2).inch
    circle[0].find_faces # actually create the circle face
    face = circle[0].faces.first

    case orientation
    when :horizontal, :vertical
      # nothing
    when :vertical_top
      entities.transform_entities Geom::Transformation.translation([0, 0, -(1.to_f / 2).inch]), face
    when :vertical_bottom
      entities.transform_entities Geom::Transformation.translation([0, 0, (1.to_f / 2).inch]), face
    end

    face.pushpull 1.inch
  end

  def self.draw_pull(entities, point, orientation)
    half_inch = (1.to_f / 2).inch # ruby makes this fucking annoying to retype
    width = 4.inch
    group = entities.add_group

    x_offset = -(width + 1) / 2
    z_offset = -half_inch / 2
    face = group.entities.add_face [
      [x_offset + 0,                 0,          z_offset],
      [x_offset + half_inch,         0,          z_offset],
      [x_offset + half_inch,         -half_inch, z_offset],
      [x_offset + half_inch + width, -half_inch, z_offset],
      [x_offset + half_inch + width, 0,          z_offset],
      [x_offset + width + 1.inch,    0,          z_offset],
      [x_offset + width + 1.inch,    -1.inch,    z_offset],
      [x_offset + 0,                 -1.inch,    z_offset],
    ]
    face.reverse! unless face.normal.samedirection?(Z_AXIS)
    face.pushpull half_inch

    # use transform_entities instead of changing the group's transformation because the latter is
    # confusing to reason about, and isn't entirely an accurate representation of the intent
    faces = group.entities.grep(Sketchup::Face)

    case orientation
    when :horizontal
      # nothing
    when :vertical, :vertical_top, :vertical_bottom
      group.entities.transform_entities Geom::Transformation.rotation(ORIGIN, Y_AXIS, 90.degrees), faces
    end

    case orientation
    when :horizontal, :vertical
      # nothing
    when :vertical_top
      group.entities.transform_entities Geom::Transformation.translation([0, 0, -(width + 1) / 2]), faces
    when :vertical_bottom
      group.entities.transform_entities Geom::Transformation.translation([0, 0, (width + 1) / 2]), faces
    end

    group.entities.transform_entities Geom::Transformation.translation(point), faces
  end
end

menu = UI.menu("Extensions")
menu.add_item("Add Shaker Cabinet...") { ShakerCabinets::add_shaker_cabinet }
