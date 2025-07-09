<?xml version='1.0' encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version='1.0'>
  <xsl:template match="phrase[@role='red']">
    <xsl:text>
        \textcolor{red}{
    </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>
        }
    </xsl:text>
  </xsl:template>

  <xsl:template match="section/simpara">
      <xsl:text>
\p </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>

</xsl:text>
  </xsl:template>

  <xsl:template match="part|chapter|appendix|
                       sect1|sect2|sect3|sect4|sect5|section" mode="label.markup">
    <xsl:text>\ref{</xsl:text>
    <xsl:value-of select="(@id|@xml:id)[1]"/>
    <xsl:text>}</xsl:text>
  </xsl:template>


  <xsl:param name="xref.with.number.and.title" select="1"></xsl:param>

  <xsl:param name="local.l10n.xml" select="document('')"/>
  <l:i18n xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0">
    <l:l10n xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0" language="en">
     <l:context name="xref-number-and-title">
        <l:template name="section" text="Rule %n, %t"/>
      </l:context>
    </l:l10n>
  </l:i18n>

  <!-- Better table formatting -->
  <xsl:param name="table.default.position">H</xsl:param>
  <xsl:param name="table.in.float">0</xsl:param>
  
  <!-- Custom table template for cleaner output -->
  <xsl:template match="table">
    <xsl:text>
\begin{table}[H]
\centering
\caption{</xsl:text>
    <xsl:apply-templates select="title"/>
    <xsl:text>}
</xsl:text>
    <xsl:apply-templates select="tgroup"/>
    <xsl:text>
\end{table}
</xsl:text>
  </xsl:template>

  <!-- Simplified tgroup template -->
  <xsl:template match="tgroup">
    <xsl:variable name="cols" select="@cols"/>
    <xsl:text>\begin{tabular}{</xsl:text>
    <xsl:for-each select="colspec">
      <xsl:text>l</xsl:text>
    </xsl:for-each>
    <xsl:text>}
\toprule
</xsl:text>
    <xsl:apply-templates select="thead"/>
    <xsl:text>\midrule
</xsl:text>
    <xsl:apply-templates select="tbody"/>
    <xsl:text>\bottomrule
\end{tabular}</xsl:text>
  </xsl:template>

  <!-- Simplified row template -->
  <xsl:template match="row">
    <xsl:for-each select="entry">
      <xsl:if test="position() > 1">
        <xsl:text> &amp; </xsl:text>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:for-each>
    <xsl:text> \\
</xsl:text>
  </xsl:template>

  <!-- Header row template -->
  <xsl:template match="thead/row">
    <xsl:for-each select="entry">
      <xsl:if test="position() > 1">
        <xsl:text> &amp; </xsl:text>
      </xsl:if>
      <xsl:text>\textbf{</xsl:text>
      <xsl:apply-templates/>
      <xsl:text>}</xsl:text>
    </xsl:for-each>
    <xsl:text> \\
</xsl:text>
  </xsl:template>

</xsl:stylesheet>


