package googledocsclone.example.googledocsclone.models;

public class Identifier {
    private String value;
    private double digit;
    private String siteId;
    private int bold=0;
    private int italic=0;

    public Identifier(String value, double digit, String siteId, int bold, int italic) {
        this.value = value;
        this.digit = digit;
        this.siteId = siteId;
        this.bold = bold;
        this.italic = italic;
    }

    public Identifier(String value, double digit, String siteId) {
        this.value = value;
        this.digit = digit;
        this.siteId = siteId;
    }

    public Identifier(String value, double digit) {
        this.value = value;
        this.digit = digit;
    }

    public Identifier(String value) {
        this.value = value;
    }

    public Identifier() {
    }

    // Getters and Setters
    public String getValue() {
        return value;
    }

    public void setValue(String value) {
        this.value = value;
    }

    public double getDigit() {
        return digit;
    }

    public void setDigit(double digit) {
        this.digit = digit;
    }

    public String getSiteId() {
        return siteId;
    }

    public void setSiteId(String siteId) {
        this.siteId = siteId;
    }

    public int getBold() {
        return bold;
    }

    public void setBold(int bold) {
        this.bold = bold;
    }

    public int getItalic() {
        return italic;
    }

    public void setItalic(int italic) {
        this.italic = italic;
    }


}
