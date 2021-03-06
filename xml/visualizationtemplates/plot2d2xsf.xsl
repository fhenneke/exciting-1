<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
xmlns:str="http://exslt.org/strings" >
  <xsl:output method="text" cdata-section-elements="at" />
  <xsl:variable name="da" select="str:tokenize(/plot2d/grid/axis[1]/@delta)" />
  <xsl:variable name="db" select="str:tokenize(/plot2d/grid/axis[2]/@delta)" />
  <xsl:variable name="grid" select="str:tokenize(/plot2d/grid/@gridticks)" />
  <xsl:variable name="newline"><xsl:text>
</xsl:text>
  </xsl:variable>
  <xsl:variable name="bohr2angstr" select="0.529177" />
  <xsl:template match="/">
    <xsl:text>
BEGIN_BLOCK_DATAGRID_2D                        
</xsl:text>  
    <xsl:value-of select="str:replace(/plot2d/title,' ','_')"/>
    <xsl:for-each select="/plot2d/function">
      <xsl:text>
BEGIN_DATAGRID_2D
</xsl:text>
      <xsl:value-of select="/plot2d/grid/@gridticks"/>
      <xsl:value-of select="$newline"/>
      <xsl:for-each select="str:tokenize(/plot2d/grid/@origin)">
        <xsl:value-of select=".*$bohr2angstr"/><xsl:text> </xsl:text>
      </xsl:for-each>
      <xsl:value-of select="$newline"/>
      <xsl:for-each select="/plot2d/grid/axis">
        <xsl:for-each select="str:tokenize(@endpointrs)">
          <xsl:value-of select=".*$bohr2angstr"/><xsl:text> </xsl:text>
        </xsl:for-each>
        <xsl:value-of select="$newline"/>
      </xsl:for-each>    

      <xsl:for-each select="row">
        <xsl:value-of select="."/>
        <xsl:value-of select="$newline"/>
      </xsl:for-each>
    
      <xsl:text>END_DATAGRID_2D
</xsl:text>
    </xsl:for-each>
    <xsl:text>END_BLOCK_DATAGRID_2D
</xsl:text>
  </xsl:template>
</xsl:stylesheet>
