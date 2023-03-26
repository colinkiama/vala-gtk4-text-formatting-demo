public class TextFormattingDemo.MainWindow : Gtk.ApplicationWindow {
    Gtk.TextView text_view;
    Gtk.TextBuffer text_buffer;
    SimpleActionGroup actions;

    public MainWindow (Gtk.Application app) {
        Object (application: app);
    }

    construct {
        this.text_view = new Gtk.TextView ();
        this.default_height = 400;
        this.default_width = 600;

        var header = new Gtk.HeaderBar ();
        this.set_titlebar (header);

        text_buffer = text_view.get_buffer ();
        text_buffer.text = "Hello World!";
        var bold_tag = text_buffer.create_tag ("bold", "weight", 700);
        var italic_tag = text_buffer.create_tag ("italic", "style", 2);
        // TODO: Figure out why underline doesn't appear for Pango.Underline.Single unless
        // the selected text is also bold
        var underline_tag = text_buffer.create_tag ("underline", "underline", Pango.Underline.SINGLE);

        text_view_add_to_context_menu (this.text_view);

        var scroll_container = new Gtk.ScrolledWindow ();
        scroll_container.child = text_view;

        this.child = scroll_container;
    }

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
        action.set_enabled (false);
        action = (SimpleAction)this.actions.lookup_action ("italic");
        action.set_enabled (false);
        action = (SimpleAction)this.actions.lookup_action ("underline");
        action.set_enabled (false);

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
