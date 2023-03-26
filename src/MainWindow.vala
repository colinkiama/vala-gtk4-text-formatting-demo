public class TextFormattingDemo.MainWindow : Gtk.ApplicationWindow {
    Gtk.TextView text_view;
    Gtk.TextBuffer text_buffer;
    SimpleActionGroup actions;

    public MainWindow (Gtk.Application app) {
        Object (application: app);
    }

    construct {
        this.text_view = new Gtk.TextView () {
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
        };

        this.default_height = 400;
        this.default_width = 600;

        var header = new Gtk.HeaderBar ();
        this.set_titlebar (header);

        text_buffer = text_view.get_buffer ();
        text_buffer.text = "Hello World!";
        text_buffer.create_tag ("bold", "weight", 700);
        text_buffer.create_tag ("italic", "style", 2);
        text_buffer.create_tag ("underline", "underline", Pango.Underline.SINGLE);

        var css_provider = new Gtk.CssProvider ();

        // 2023-03-26: Single underlines aren't showing in elementary OS without
        // setting the line-height or also setting text to bold.
        css_provider.load_from_data ((uint8[])"textview { line-height: 1.2; }");

        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        text_view_add_to_context_menu (this.text_view);

        var scroll_container = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = text_view,
            vexpand = true,
            hexpand = true
        };

        var panels_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            homogeneous = true,
            margin_top = 6,
            margin_end = 12,
            margin_start = 12,
            margin_bottom = 6
        };

        var bold_toggle = new Gtk.ToggleButton () {
            action_name = "format.bold",
            icon_name = "format-text-bold-symbolic",
            can_focus = false,
        };

        bold_toggle.insert_action_group ("format", actions);

        var italic_toggle = new Gtk.ToggleButton () {
            action_name = "format.italic",
            icon_name = "format-text-italic-symbolic",
            can_focus = false,
            margin_start = 4,
            margin_end = 4
        };

        italic_toggle.insert_action_group ("format", actions);

        var underline_toggle = new Gtk.ToggleButton () {
            action_name = "format.underline",
            icon_name = "format-text-underline-symbolic",
            can_focus = false,
        };

        underline_toggle.insert_action_group ("format", actions);

        panels_box.append (bold_toggle);
        panels_box.append (italic_toggle);
        panels_box.append (underline_toggle);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.append (panels_box);
        box.append (scroll_container);

        this.child = box;
        this.text_view.grab_focus ();
    }

    // Adapted from GTK 4 Widget Factory Demo: https://gitlab.gnome.org/GNOME/gtk/-/tree/main/demos/widget-factory  
    void text_view_add_to_context_menu (Gtk.TextView text_view) {
        Menu menu = new Menu ();
        MenuItem item;
        SimpleAction action;
        ActionEntry entries[] = {
            { "bold", null, null, "false", toggle_format},
            { "italic", null, null, "false", toggle_format },
            { "underline", null, null, "false", toggle_format },
        };

        this.actions = new SimpleActionGroup ();
        this.actions.add_action_entries (entries, this.text_view);

        action = (SimpleAction)this.actions.lookup_action ("bold");
        action.set_enabled (true);
        action = (SimpleAction)this.actions.lookup_action ("italic");
        action.set_enabled (true);
        action = (SimpleAction)this.actions.lookup_action ("underline");
        action.set_enabled (true);

        this.text_view.insert_action_group ("format", this.actions);

        item = new MenuItem ("Bold", "format.bold");
        item.set_attribute ("touch-icon", "s", "format-text-bold-symbolic");
        menu.append_item (item);
        item = new MenuItem ("italic", "format.italic");
        item.set_attribute ("touch-icon", "s", "format-text-italic-symbolic");
        menu.append_item (item);
        item = new MenuItem ("Underline", "format.underline");
        item.set_attribute ("touch-icon", "s", "format-text-underline-symbolic");
        menu.append_item (item);

        this.text_view.set_extra_menu (menu);

        this.text_buffer.changed.connect (text_changed);
        this.text_buffer.mark_set.connect (text_changed_full);
    }

    void text_changed (Gtk.TextBuffer buffer) {
        text_changed_full (buffer, Gtk.TextIter (), new Gtk.TextMark ("", false));
    }

    void text_changed_full (Gtk.TextBuffer buffer, Gtk.TextIter iter_in, Gtk.TextMark mark) {
        SimpleAction bold = (SimpleAction)actions.lookup_action ("bold");
        SimpleAction italic = (SimpleAction)actions.lookup_action ("italic");
        SimpleAction underline = (SimpleAction)actions.lookup_action ("underline");
        Gtk.TextIter iter = iter_in;
        Gtk.TextTagTable tags = this.text_buffer.get_tag_table ();
        Gtk.TextTag bold_tag = tags.lookup ("bold");
        Gtk.TextTag italic_tag = tags.lookup ("italic");
        Gtk.TextTag underline_tag = tags.lookup ("underline");
        bool all_bold = true;
        bool all_italic = true;
        bool all_underline = true;
        Gtk.TextIter start, end;
        bool has_selection = this.text_buffer.get_selection_bounds (out start, out end);

        bold.set_enabled (true);
        italic.set_enabled (true);
        underline.set_enabled (true);

        if (!has_selection) {
            // Get cursor position and set action state
            // based on if tag is applied in cursor position
            int cursor_position = this.text_buffer.cursor_position;
            Gtk.TextIter cursor_iter;
            this.text_buffer.get_iter_at_offset (out cursor_iter, cursor_position);
            bold.set_state (cursor_iter.has_tag (bold_tag));
            italic.set_state (cursor_iter.has_tag (italic_tag));
            underline.set_state (cursor_iter.has_tag (underline_tag));
            return;
        }

        iter.assign (start);

        while (!iter.equal (end)) {
            all_bold &= iter.has_tag (bold_tag);
            all_italic &= iter.has_tag (italic_tag);
            all_underline &= iter.has_tag (underline_tag);
            iter.forward_char ();
        }

        bold.set_state (all_bold);
        italic.set_state (all_italic);
        underline.set_state (all_underline);
    }

    void toggle_format (SimpleAction action, Variant value) {
        Gtk.TextIter start, end;
        string name = action.get_name ();

        action.set_state (value);

        this.text_buffer.get_selection_bounds (out start, out end);

        if (value.get_boolean ()) {
            this.text_buffer.apply_tag_by_name (name, start, end);
        } else {
            this.text_buffer.remove_tag_by_name (name, start, end);
        }
    }
}
