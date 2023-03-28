public struct FormattingRequest {
    public Gee.ArrayList<FormattingType?> formatting_types;
    public int insert_offset;
    public int insert_length;
}

public enum FormattingType {
    BOLD,
    ITALIC,
    UNDERLINE;
}