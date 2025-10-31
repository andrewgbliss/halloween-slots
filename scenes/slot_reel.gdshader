shader_type canvas_item;

// The scroll offset (which symbol to center on, can be fractional for smooth scrolling)
uniform float scroll_offset : hint_range(0.0, 12.0) = 0.0;

// Number of frames in the sprite sheet
uniform int h_frames = 6;
uniform int v_frames = 2;

// How many symbols to display vertically
uniform int visible_symbols = 3;

void fragment() {
	int total_frames = h_frames * v_frames;
	float frame_width = 1.0 / float(h_frames);
	float frame_height = 1.0 / float(v_frames);
	
	// Calculate which symbol we're currently looking at
	// UV.y ranges from 0.0 (top) to 1.0 (bottom)
	// We want to map this to visible_symbols worth of symbols
	float y_position = UV.y * float(visible_symbols);
	
	// Offset by scroll to create movement
	// Subtract so that increasing scroll_offset moves symbols down
	y_position -= scroll_offset;
	
	// Make it wrap around infinitely
	y_position = mod(y_position + float(total_frames) * 1000.0, float(total_frames));
	
	// Which symbol index (0-11 for a 6x2 grid)
	int symbol_idx = int(floor(y_position));
	
	// Position within that symbol (0.0 to 1.0)
	float y_within_symbol = fract(y_position);
	
	// Convert symbol index to row/column in sprite sheet
	int col = symbol_idx % h_frames;
	int row = symbol_idx / h_frames;
	
	// Calculate UV in the texture atlas
	vec2 tex_uv;
	tex_uv.x = (float(col) + UV.x) * frame_width;
	tex_uv.y = (float(row) + y_within_symbol) * frame_height;
	
	// Clamp to prevent bleeding
	tex_uv = clamp(tex_uv, vec2(0.001), vec2(0.999));
	
	COLOR = texture(TEXTURE, tex_uv);
}

