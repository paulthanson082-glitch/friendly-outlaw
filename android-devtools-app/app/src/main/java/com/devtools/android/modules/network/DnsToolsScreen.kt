package com.devtools.android.modules.network

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.devtools.android.ui.components.ErrorCard

@Composable
fun DnsToolsScreen(vm: DnsToolsViewModel = viewModel()) {
    val result by vm.result.collectAsState()
    val isLoading by vm.isLoading.collectAsState()
    val error by vm.error.collectAsState()

    var host by rememberSaveable { mutableStateOf("") }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
    ) {
        item {
            Spacer(modifier = Modifier.height(16.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                OutlinedTextField(
                    value = host,
                    onValueChange = { host = it },
                    label = { Text("Hostname or IP") },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                    enabled = !isLoading,
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Uri,
                        imeAction = ImeAction.Search,
                    ),
                    keyboardActions = KeyboardActions(
                        onSearch = { if (!isLoading) vm.lookup(host.trim()) }
                    ),
                )
                Spacer(modifier = Modifier.width(8.dp))
                Button(
                    onClick = { vm.lookup(host.trim()) },
                    enabled = !isLoading && host.isNotBlank(),
                ) {
                    Text("Lookup")
                }
            }
        }

        if (isLoading) {
            item {
                Spacer(modifier = Modifier.height(24.dp))
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    CircularProgressIndicator()
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("Looking up…", style = MaterialTheme.typography.bodyMedium)
                }
            }
        }

        error?.let { msg ->
            item {
                Spacer(modifier = Modifier.height(8.dp))
                ErrorCard(message = msg, onRetry = { vm.lookup(host.trim()) })
            }
        }

        result?.let { dns ->
            // A records
            item {
                Spacer(modifier = Modifier.height(16.dp))
                SectionLabel("A / AAAA Records")
            }
            if (dns.addresses.isEmpty()) {
                item { ResultText("No addresses found") }
            } else {
                dns.addresses.forEach { addr ->
                    item { ResultText(addr) }
                }
            }

            // PTR records
            item {
                Spacer(modifier = Modifier.height(8.dp))
                SectionLabel("Reverse PTR")
            }
            if (dns.reversePtrs.isEmpty()) {
                item { ResultText("No PTR records") }
            } else {
                dns.reversePtrs.distinct().forEach { ptr ->
                    item { ResultText(ptr) }
                }
            }

            // Whois
            if (dns.whoisOutput.isNotBlank()) {
                item {
                    Spacer(modifier = Modifier.height(8.dp))
                    SectionLabel("Whois")
                    Spacer(modifier = Modifier.height(4.dp))
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Text(
                            text = dns.whoisOutput,
                            style = MaterialTheme.typography.bodySmall,
                            modifier = Modifier.padding(12.dp),
                        )
                    }
                }
            }
        }

        item { Spacer(modifier = Modifier.height(16.dp)) }
    }
}

@Composable
private fun SectionLabel(text: String) {
    Column {
        Text(text, fontWeight = FontWeight.Bold)
        HorizontalDivider(modifier = Modifier.padding(top = 2.dp))
    }
}

@Composable
private fun ResultText(value: String) {
    Text(
        text = value,
        style = MaterialTheme.typography.bodyMedium,
        modifier = Modifier.padding(vertical = 4.dp),
    )
}
