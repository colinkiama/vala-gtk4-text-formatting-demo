public class TextFormattingDemo.MainWindow : Gtk.ApplicationWindow {
    private Gtk.TextView text_view;
    private Gtk.TextBuffer text_buffer;
    private SimpleActionGroup actions;

    public const string FORMAT_ACTION_GROUP_PREFIX = "format";
    public const string FORMAT_ACTION_PREFIX = FORMAT_ACTION_GROUP_PREFIX + ".";
    public const string FORMAT_ACTION_BOLD = "bold";
    public const string FORMAT_ACTION_ITALIC = "italic";
    public const string FORMAT_ACTION_UNDERLINE = "underline";

    public const string ICON_NAME_BOLD = "format-text-bold-symbolic";
    public const string ICON_NAME_ITALIC = "format-text-italic-symbolic";
    public const string ICON_NAME_UNDERLINE = "format-text-underline-symbolic";

    public MainWindow (Gtk.Application app) {
        Object (application: app);
    }

    static construct {
        // Add additional CSS Styling
        var css_provider = new Gtk.CssProvider ();

        // 2023-03-26: Single underlines aren't showing in elementary OS without
        // setting the line-height or also setting text to bold.
        css_provider.load_from_data ((uint8[])"textview { line-height: 1.2; }");

        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    construct {
        this.default_height = 400;
        this.default_width = 600;

        var header = new Gtk.HeaderBar ();
        this.set_titlebar (header);

        this.text_view = new Gtk.TextView () {
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
        };

        this.actions = this.create_formatting_actions ();
        this.text_buffer = this.create_text_buffer ();
        this.add_formatting_options_to_text_view_context_menu (this.text_view);

        var scroll_wrapper = this.create_scroll_wrapper ();
        var formatting_panel = this.create_formatting_panel ();

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.append (formatting_panel);
        box.append (scroll_wrapper);

        this.child = box;

        this.text_view.grab_focus ();
    }

    private SimpleActionGroup create_formatting_actions () {
        var actions_to_return = new SimpleActionGroup ();

        ActionEntry[] entries = {
            { FORMAT_ACTION_BOLD, null, null, "false", toggle_format},
            { FORMAT_ACTION_ITALIC, null, null, "false", toggle_format },
            { FORMAT_ACTION_UNDERLINE, null, null, "false", toggle_format },
        };

        SimpleAction action;

        actions_to_return.add_action_entries (entries, this.text_view);

        action = (SimpleAction)actions_to_return.lookup_action (FORMAT_ACTION_BOLD);
        action.set_enabled (true);

        action = (SimpleAction)actions_to_return.lookup_action (FORMAT_ACTION_ITALIC);
        action.set_enabled (true);

        action = (SimpleAction)actions_to_return.lookup_action (FORMAT_ACTION_UNDERLINE);
        action.set_enabled (true);

        return actions_to_return;
    }

    private Gtk.TextBuffer create_text_buffer () {
        var buffer_to_return = text_view.get_buffer ();

        buffer_to_return.text = "Hello World!";
        buffer_to_return.create_tag (FORMAT_ACTION_BOLD, "weight", 700);
        buffer_to_return.create_tag (FORMAT_ACTION_ITALIC, "style", 2);
        buffer_to_return.create_tag (FORMAT_ACTION_UNDERLINE, "underline", Pango.Underline.SINGLE);

        return buffer_to_return;
    }

    // Adapted from GTK 4 Widget Factory Demo: https://gitlab.gnome.org/GNOME/gtk/-/tree/main/demos/widget-factory  
    private void add_formatting_options_to_text_view_context_menu (Gtk.TextView text_view) {
        Menu menu = this.create_formatting_menu ();
        this.text_view.set_extra_menu (menu);
        this.text_buffer.changed.connect (this.handle_text_view_change);
        this.text_buffer.mark_set.connect (this.handle_text_view_mark_set);
    }

    private Gtk.ScrolledWindow create_scroll_wrapper () {
        return new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = this.text_view,
            vexpand = true,
            hexpand = true
        };
    }

    private Gtk.Box create_formatting_panel () {
        var panel_to_return = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            homogeneous = true,
            margin_top = 6,
            margin_end = 12,
            margin_start = 12,
            margin_bottom = 6
        };

        var bold_toggle = new Gtk.ToggleButton () {
            action_name = FORMAT_ACTION_PREFIX + FORMAT_ACTION_BOLD,
            icon_name = ICON_NAME_BOLD,
            can_focus = false,
        };

        bold_toggle.insert_action_group (FORMAT_ACTION_GROUP_PREFIX, actions);

        var italic_toggle = new Gtk.ToggleButton () {
            action_name = FORMAT_ACTION_PREFIX + FORMAT_ACTION_ITALIC,
            icon_name = ICON_NAME_ITALIC,
            can_focus = false,
            margin_start = 4,
            margin_end = 4
        };

        italic_toggle.insert_action_group (FORMAT_ACTION_GROUP_PREFIX, actions);

        var underline_toggle = new Gtk.ToggleButton () {
            action_name = FORMAT_ACTION_PREFIX + FORMAT_ACTION_UNDERLINE,
            icon_name = ICON_NAME_UNDERLINE,
            can_focus = false,
        };

        underline_toggle.insert_action_group (FORMAT_ACTION_GROUP_PREFIX, actions);

        panel_to_return.append (bold_toggle);
        panel_to_return.append (italic_toggle);
        panel_to_return.append (underline_toggle);

        return panel_to_return;
    }

    private Menu create_formatting_menu () {
        Menu menu = new Menu ();
        MenuItem item;

        this.text_view.insert_action_group (FORMAT_ACTION_GROUP_PREFIX, this.actions);

        item = new MenuItem ("Bold", FORMAT_ACTION_PREFIX + FORMAT_ACTION_BOLD);
        item.set_attribute ("touch-icon", "s", ICON_NAME_BOLD);
        menu.append_item (item);

        item = new MenuItem ("Italic", FORMAT_ACTION_PREFIX + FORMAT_ACTION_ITALIC);
        item.set_attribute ("touch-icon", "s", ICON_NAME_ITALIC);
        menu.append_item (item);

        item = new MenuItem ("Underline", FORMAT_ACTION_PREFIX + FORMAT_ACTION_UNDERLINE);
        item.set_attribute ("touch-icon", "s", ICON_NAME_UNDERLINE);
        menu.append_item (item);

        return menu;
    }

    private void handle_text_view_change (Gtk.TextBuffer buffer) {
        SimpleAction bold_action = this.get_formatting_action (FORMAT_ACTION_BOLD);
        SimpleAction italic_action = this.get_formatting_action (FORMAT_ACTION_ITALIC);
        SimpleAction underline_action = this.get_formatting_action (FORMAT_ACTION_UNDERLINE);
        Gtk.TextTagTable text_buffer_tags = this.text_buffer.get_tag_table ();
        Gtk.TextTag bold_tag = text_buffer_tags.lookup (FORMAT_ACTION_BOLD);
        Gtk.TextTag italic_tag = text_buffer_tags.lookup (FORMAT_ACTION_ITALIC);
        Gtk.TextTag underline_tag = text_buffer_tags.lookup (FORMAT_ACTION_UNDERLINE);
        Gtk.TextIter iterator = Gtk.TextIter ();
        Gtk.TextIter start_iterator, end_iterator;
        bool is_all_bold = true;
        bool is_all_italic = true;
        bool is_all_underline = true;
        bool has_selection = this.text_buffer.get_selection_bounds (out start_iterator, out end_iterator);

        if (!has_selection) {
            // Get cursor position and set action state
            // based on if tag is applied in cursor position
            int cursor_position = this.text_buffer.cursor_position;
            Gtk.TextIter cursor_iter;
            this.text_buffer.get_iter_at_offset (out cursor_iter, cursor_position);
            bold_action.set_state (cursor_iter.has_tag (bold_tag));
            italic_action.set_state (cursor_iter.has_tag (italic_tag));
            underline_action.set_state (cursor_iter.has_tag (underline_tag));
            return;
        }

        iterator.assign (start_iterator);

        while (!iterator.equal (end_iterator)) {
            is_all_bold &= iterator.has_tag (bold_tag);
            is_all_italic &= iterator.has_tag (italic_tag);
            is_all_underline &= iterator.has_tag (underline_tag);
            iterator.forward_char ();
        }

        bold_action.set_state (is_all_bold);
        italic_action.set_state (is_all_italic);
        underline_action.set_state (is_all_underline);
    }

    private void handle_text_view_mark_set (Gtk.TextBuffer buffer, Gtk.TextIter iterator, Gtk.TextMark mark) {
        this.handle_text_view_change (buffer);
    }

    private void toggle_format (SimpleAction action, Variant value) {
        Gtk.TextIter start_iterator, end_itrator;
        string name = action.get_name ();

        action.set_state (value);

        this.text_buffer.get_selection_bounds (out start_iterator, out end_itrator);

        if (value.get_boolean ()) {
            this.text_buffer.apply_tag_by_name (name, start_iterator, end_itrator);
        } else {
            this.text_buffer.remove_tag_by_name (name, start_iterator, end_itrator);
        }
    }

    private SimpleAction get_formatting_action (string name) {
        return this.actions.lookup_action (name) as SimpleAction;
    }
}
